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
        
        UIApplication.shared.isIdleTimerDisabled = true
        setupAVCapture()
        
        loopPlayer.initDemo()
        loopPlayer.start()
    }
    
    func setupAVCapture() {
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                           mediaType: .video,
                                                           position: .front).devices.first
        
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
