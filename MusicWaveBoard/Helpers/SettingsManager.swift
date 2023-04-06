//
//  SettingsManager.swift
//  MusicWaveBoard
//
//  Created by Vitaliy Gribko on 05.04.2023.
//

import Foundation

struct SampleTrack: Codable {
    var track: String
    var keyWords: String
}

class SettingsManager {
    
    static func setTrack(index: Int, track: String, keyWords: String) {
        let sampleTrack = SampleTrack(track: track, keyWords: keyWords)
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(sampleTrack) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: String(index))
        }
    }
    
    static func getTrack(index: Int) -> SampleTrack? {
        let defaults = UserDefaults.standard
        if let sampleTrack = defaults.object(forKey: String(index)) as? Data {
            let decoder = JSONDecoder()
            if let loadedPerson = try? decoder.decode(SampleTrack.self, from: sampleTrack) {
                return loadedPerson
            }
        }
        
        return nil
    }
    
    static func clearTrack(index: Int) {
        UserDefaults.standard.removeObject(forKey: String(index))
    }
    
    static func setVolume(index: Int, volume: Int) {
        let defaults = UserDefaults.standard
        let key = "volume_" + String(index)
        defaults.set(volume, forKey: key)
    }
    
    static func getVolume(index: Int) -> Int {
        let defaults = UserDefaults.standard
        let key = "volume_" + String(index)
        
        let volume = defaults.object(forKey: key) as? Int ?? 100
        return volume
    }
}
