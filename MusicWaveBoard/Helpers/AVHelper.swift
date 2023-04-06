//
//  AVHelper.swift
//  MusicWaveBoard
//
//  Created by v.gribko on 06.04.2023.
//

import AVFoundation

class AVHelper {
    
    static func prepareAudioSession(category: AVAudioSession.Category) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(category)
            try audioSession.setMode(AVAudioSession.Mode.default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        }
        catch {}
    }
}
