//
//  ViewController.swift
//  MusicWaveBoard
//
//  Created by Vitaliy Gribko on 17.09.2021.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var previewLayer = AVCaptureVideoPreviewLayer()
    let session = AVCaptureSession()
    let output = AVCaptureMetadataOutput()
    let loopPlayer = LoopPlayer()
    
    var rootLayer: CALayer! = nil
    var bufferSize: CGSize = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.viewControllers?.remove(at: 3)
        tabBarController?.viewControllers?.remove(at: 2)
        
        UIApplication.shared.isIdleTimerDisabled = true
        setupAVCapture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loopPlayer.preparePlayer()
        loopPlayer.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        loopPlayer.stop()
    }
    
    func setupAVCapture() {
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                           mediaType: .video,
                                                           position: .back).devices.first
        
        do {
            try videoDevice?.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch {
            fatalError(error.localizedDescription)
        }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
            session.addInput(deviceInput)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        session.addOutput(output)
        
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
    }
}
