//
//  VolumeView.swift
//  MusicWaveBoard
//
//  Created by Vitaliy Gribko on 20.09.2021.
//

import UIKit

class VolumeView: UIView {
    
    @IBOutlet weak var volumeSlider: UISlider!

    override func draw(_ rect: CGRect) {
        volumeSlider.value = 80
    }

    @IBAction func tappedOk(_ sender: UIButton) {
        hideView()
    }
    
    @IBAction func tappedCancel(_ sender: UIButton) {
        hideView()
    }
    
    private func hideView() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {

           self.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)

         }) { (success) in
           self.removeFromSuperview()
         }
    }
}
