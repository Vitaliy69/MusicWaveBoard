//
//  VisionObjectRecognitionViewController.swift
//  MusicWaveBoard
//
//  Created by Vitaliy Gribko on 17.09.2021.
//

import UIKit
import AVFoundation
import Vision

struct GamePieceTime {
    var firstSeen: Int
    var lastSeen: Int
}

class VisionObjectRecognitionViewController: ViewController {
    
    @IBOutlet var volumeView: UIView!
    
    private var detectionOverlay: CALayer! = nil
    
    // Vision parts
    private var requests = [VNRequest]()
    private var gamePieces = [String: GamePieceTime]()
    
    private let detectionOverlayName = "DetectionOverlay"
    private var recordName = "mic.circle"
    
    private let minConfidence: Float = 0.9
    private let msToAppear = 1000
    private let msToDisappear = 2000
    
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        
        guard let modelURL = Bundle.main.url(forResource: "model", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        self.drawVisionRequestResults(results)
                    }
                })
            })
            self.requests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        
        return error
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self.view) else { return }
        
        if let layer = self.view.layer.hitTest(point) {
            if let name = layer.name, name != detectionOverlayName {
                if name == recordName {
                    switch name {
                    case "mic.circle":
                        self.recordName = "mic.circle.fill"
                    default:
                        self.recordName = "mic.circle"
                    }
                } else {
                    showGameChipActions(title: name)
                }
            }
        }
    }
    
    func showGameChipActions(title: String) {
        let alert = UIAlertController(title: title, message: "Please select an action", preferredStyle: .alert)
        
        let volume = UIAlertAction(title: "Volume", style: .default, handler: { (UIAlertAction) in
            self.volumeView.center = self.view.center
            self.volumeView.alpha = 1
            self.volumeView.transform = CGAffineTransform(scaleX: 0.8, y: 1.2)
            
            self.view.addSubview(self.volumeView)
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [],  animations: {
                self.volumeView.transform = .identity
            })
        })
        volume.setValue(UIImage(systemName: "speaker.wave.3.fill"), forKey: "image")
        alert.addAction(volume)
        
        let mute = UIAlertAction(title: "Mute", style: .destructive, handler: { (UIAlertAction) in
            
        })
        mute.setValue(UIImage(systemName: "speaker.slash.fill"), forKey: "image")
        alert.addAction(mute)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (UIAlertAction) in
            
        }))
        
        alert.popoverPresentationController?.sourceView = self.view
        
        self.present(alert, animated: true, completion: {

        })
    }
    
    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        let now = Int(Date().timeIntervalSince1970 * 1000)
        
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence
            let topLabelObservation = objectObservation.labels[0]
        
            let identifier = topLabelObservation.identifier
            let confidence = topLabelObservation.confidence
            
            if (confidence < minConfidence) {
                continue
            }
            
            if gamePieces.keys.contains(identifier) {
                var current = gamePieces[identifier]!
                current.lastSeen = now
                gamePieces[identifier] = current
                
                if (now - current.firstSeen < msToAppear) {
                    continue
                }
            } else {
                let gamePieceTime = GamePieceTime(firstSeen: now, lastSeen: now)
                gamePieces[identifier] = gamePieceTime
                continue
            }
            
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds, identifier: identifier)
            let textLayer = self.createTextSubLayerInBounds(objectBounds, identifier: identifier, confidence: confidence)
            
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
        }
        
        // Add menu elements
        let record = createMenuOverlay(CGRect(x: detectionOverlay.bounds.maxX - 95, y: detectionOverlay.bounds.maxY - 105, width: 32, height: 32), identifier: recordName)
        detectionOverlay.addSublayer(record)
        
        for gp in gamePieces {
            if (now - gp.value.lastSeen > msToAppear) {
                gamePieces.removeValue(forKey: gp.key)
            }
        }
        
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let exifOrientation = CGImagePropertyOrientation.downMirrored
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    override func setupAVCapture() {
        super.setupAVCapture()
        
        // setup Vision parts
        setupLayers()
        updateLayerGeometry()
        setupVision()
        
        // start the capture
        startCaptureSession()
    }
    
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = detectionOverlayName
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = identifier
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)"))
        let largeFont = UIFont(name: "Helvetica", size: 18.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont, NSAttributedString.Key.foregroundColor: UIColor.red], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 1, height: 1)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect, identifier: String) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = identifier
        shapeLayer.backgroundColor = CGColor(red: 0, green: 0, blue: 1, alpha: 0.5)
        shapeLayer.cornerRadius = 10
        
        let myImage = UIImage(named: "acoustic-guitar")?.cgImage
        shapeLayer.contents = myImage
        
        // rotate the layer into screen orientation and scale
        shapeLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        
        return shapeLayer
    }
    
    func createMenuOverlay(_ bounds: CGRect, identifier: String) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = identifier
        
        let myImage = UIImage(systemName: identifier)?.cgImage
        shapeLayer.contents = myImage
        
        // rotate the layer into screen orientation and scale
        shapeLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        
        return shapeLayer
    }
}
