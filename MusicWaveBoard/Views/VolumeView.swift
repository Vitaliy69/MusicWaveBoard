//
//  VolumeView.swift
//  MusicWaveBoard
//
//  Created by Vitaliy Gribko on 20.09.2021.
//

import UIKit

class VolumeView: UIView {
    
    @IBOutlet weak var volumeSlider: UISlider!
    var completed: (() -> ())?
    
    private var index: Int? = nil
    
    func setCurrentIndex(index: String) {
        self.index = Int(index) ?? 100
        let volume = SettingsManager.getVolume(index: self.index!)
        volumeSlider.value = Float(volume)
    }
    
    @IBAction func tappedOk(_ sender: UIButton) {
        SettingsManager.setVolume(index: index!, volume: Int(volumeSlider.value))
        hideView()
        completed?()
    }
    
    @IBAction func tappedCancel(_ sender: UIButton) {
        hideView()
        completed?()
    }
    
    private func hideView() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            
            self.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            
        }) { (success) in
            self.removeFromSuperview()
        }
    }
}
