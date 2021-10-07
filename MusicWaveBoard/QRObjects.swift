//
//  QRObjects.swift
//  MusicWaveBoard
//
//  Created by Vitaliy Gribko on 17.09.2021.
//

import UIKit
import AVFoundation

class QRObjects: ViewController {
    
    @IBOutlet var volumeView: UIView!
    
    private var detectionOverlay: CALayer! = nil
    
    private weak var drawTimer: Timer?
    private weak var changeRectTimer: Timer?
    
    private let detectionOverlayName = "DetectionOverlay"
    private var recordName = "Mic"
    
    private var lastSeenPiece = [String: (bounds: CGRect, timestamp: Int)]()
    private let aliveTimeMs = 1500
    
    private var searchRectNum = 0
    private let searchRects = [ CGRect(x: 0, y: 0, width: 0.33, height: 1),
                                CGRect(x: 0.165, y: 0, width: 0.33, height: 1),
                                CGRect(x: 0.33, y: 0, width: 0.33, height: 1),
                                CGRect(x: 0.495, y: 0, width: 0.33, height: 1),
                                CGRect(x: 0.66, y: 0, width: 0.33, height: 1),
                                CGRect(x: 0.825, y: 0, width: 0.165, height: 1)]
    
    override func setupAVCapture() {
        super.setupAVCapture()
        
        setupLayers()
        drawMenu()
        updateLayerGeometry()
        
        session.startRunning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        drawTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                           target: self,
                                           selector: #selector(drawVisibleQR),
                                           userInfo: nil,
                                           repeats: true)
        
        changeRectTimer = Timer.scheduledTimer(timeInterval: 0.15,
                                           target: self,
                                           selector: #selector(changeSearchRect),
                                           userInfo: nil,
                                           repeats: true)
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        drawTimer?.invalidate()
        changeRectTimer?.invalidate()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self.view) else { return }
        
        if let layer = self.view.layer.hitTest(point) {
            if let name = layer.name, name != detectionOverlayName {
                if name == recordName {
                    switch name {
                    case "Mic":
                        self.recordName = "Mic_sel"
                    default:
                        self.recordName = "Mic"
                    }
                    
                    detectionOverlay.sublayers = nil
                    drawMenu()
                    updateLayerGeometry()
                } else {
                    showGameChipActions(title: name)
                }
            }
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        updateVisibleQR(metadataObjects: metadataObjects)
    }
    
    private func setupLayers() {
        rootLayer = view.layer
        previewLayer.frame = rootLayer.bounds
        previewLayer.bounds = CGRect(x: 0.0,
                                     y: 0.0,
                                     width: bufferSize.width,
                                     height: bufferSize.height)
        rootLayer.addSublayer(previewLayer)
        
        detectionOverlay = CALayer()
        detectionOverlay.name = detectionOverlayName
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    private func updateLayerGeometry() {
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
        
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
    }
    
    private func showGameChipActions(title: String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        
        let volume = UIAlertAction(title: "Volume", style: .default, handler: { (UIAlertAction) in
            self.volumeView.center = self.view.center
            self.volumeView.alpha = 0.8
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
        
        alert.view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        alert.view.tintColor = UIColor.systemOrange
        alert.view.layer.cornerRadius = 14
        
        self.present(alert, animated: true, completion: {
            
        })
    }
    
    private func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = identifier
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)"))
        let largeFont = UIFont(name: "Helvetica", size: 36.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont,
                                       NSAttributedString.Key.foregroundColor: UIColor.systemOrange],
                                      range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 1, height: 1)
        textLayer.foregroundColor = UIColor.systemOrange.cgColor
        textLayer.contentsScale = 2.0 // retina rendering
        
        return textLayer
    }
    
    private func createRoundedRectLayerWithBounds(_ bounds: CGRect, identifier: String) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = identifier
        shapeLayer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8).cgColor
        shapeLayer.cornerRadius = 32
        
        let myImage = UIImage(named: "Guit")?.cgImage
        shapeLayer.contents = myImage
        
        // rotate the layer into screen orientation and scale
        shapeLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        
        return shapeLayer
    }
    
    private func createMenuOverlay(_ bounds: CGRect, identifier: String) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = identifier
        
        let myImage = UIImage(named: identifier)?.cgImage
        shapeLayer.contents = myImage
        
        // rotate the layer into screen orientation and scale
        shapeLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        
        return shapeLayer
    }
    
    private func drawMenu() {
        let record = createMenuOverlay(CGRect(x: detectionOverlay.bounds.maxX - 280,
                                              y: detectionOverlay.bounds.maxY - 200,
                                              width: 96,
                                              height: 96),
                                       identifier: recordName)
        
        detectionOverlay.addSublayer(record)
    }
    
    private func updateVisibleQR(metadataObjects: [AVMetadataObject]) {
        let now = Int(Date().timeIntervalSince1970 * 1000)
        
        for object in metadataObjects {
            if let o = object as? AVMetadataMachineReadableCodeObject {
                if o.type == AVMetadataObject.ObjectType.qr, let name = o.stringValue {
                    
                    let objectBounds = CGRect(x: o.bounds.minX * bufferSize.width,
                                              y: o.bounds.minY * bufferSize.height,
                                              width: o.bounds.width * bufferSize.width,
                                              height: o.bounds.height * bufferSize.height)
                    
                    lastSeenPiece[name] = (objectBounds, now)
                }
            }
        }
    }
    
    @objc private func drawVisibleQR() {
        detectionOverlay.sublayers = nil
        drawMenu()
        
        let now = Int(Date().timeIntervalSince1970 * 1000)
        
        for object in lastSeenPiece {
            if object.value.timestamp + aliveTimeMs > now {
                let shapeLayer = createRoundedRectLayerWithBounds(object.value.bounds, identifier: object.key)
                let textLayer = createTextSubLayerInBounds(object.value.bounds, identifier: object.key)
                
                shapeLayer.addSublayer(textLayer)
                detectionOverlay.addSublayer(shapeLayer)
            } else {
                lastSeenPiece.removeValue(forKey: object.key)
            }
        }
        
        updateLayerGeometry()
    }
    
    @objc private func changeSearchRect() {
        output.rectOfInterest = searchRects[searchRectNum]
        if searchRectNum == searchRects.count - 1 {
            searchRectNum = 0
        } else {
            searchRectNum += 1
        }
    }
}
