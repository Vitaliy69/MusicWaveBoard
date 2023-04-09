//
//  LoopPlayer.swift
//  MusicWaveBoard
//
//  Created by Vitaliy Gribko on 22.10.2021.
//

import UIKit
import AVFoundation

class Latch {
    var value: Bool = false
}

class LoopPlayer {
    
    private var audioUnits = [String: AVAudioUnitEQ]()
    private var audioPlayers = [String: AVAudioPlayerNode]()
    private var audioFiles = [String: AVAudioFile]()
    private var audioEngine = AVAudioEngine()
    
    private var fadeInMap = [String: DispatchWorkItem]()
    private var fadeOutMap = [String: DispatchWorkItem]()
    
    private let fadeSecs: Float = 1
    private let maxDb: Float = 0
    private let minDb: Float = -96
    
    private let tracks = 1..<25
    
    func start() {
        AVHelper.prepareAudioSession(category: AVAudioSession.Category.playback)
        preparePlayer()
        
        for index in tracks {
            let key = String.localizedStringWithFormat("%.2d", index)
            
            guard audioPlayers[key] != nil, audioUnits[key] != nil, audioFiles[key] != nil else { continue }
            
            let looping = loopWholeFile(file: audioFiles[key]!, player: audioPlayers[key]!)
            looping.value = true
            
            audioUnits[key]!.globalGain = minDb
        }
    }
    
    func stop() {
        audioEngine.stop()
    }
    
    private func preparePlayer() {
        for index in tracks {
            let key = String.localizedStringWithFormat("%.2d", index)
            let track = SettingsManager.getTrack(index: index)?.track
            guard track != nil else { continue }
            guard let filePath = Bundle.main.path(forResource: track, ofType: "wav", inDirectory: "Samples") else { continue }
            
            let fileURL = URL(fileURLWithPath: filePath)
            do {
                let audioFile = try AVAudioFile(forReading: fileURL)
                audioFiles[key] = audioFile
                
                let audioUnit = AVAudioUnitEQ()
                audioUnits[key] = audioUnit
                audioEngine.attach(audioUnit)
                
                let audioPlayer = AVAudioPlayerNode()
                audioPlayers[key] = audioPlayer
                audioEngine.attach(audioPlayer)
                
                audioEngine.connect(audioPlayer, to: audioUnit, format: nil)
                audioEngine.connect(audioUnit, to: audioEngine.mainMixerNode, format: nil)
                
            } catch {
                print(error)
            }
        }
        
        do {
            if (!audioEngine.attachedNodes.isEmpty) {
                try audioEngine.start()
            }
        } catch {
            print(error)
        }
    }
    
    private func loopWholeFile(file: AVAudioFile, player: AVAudioPlayerNode) -> Latch {
        let looping = Latch()
        let frames = file.length
        
        let sampleRate = file.processingFormat.sampleRate
        var segmentTime: AVAudioFramePosition = 0
        var segmentCompletion: AVAudioNodeCompletionHandler!
        segmentCompletion = {
            if looping.value {
                segmentTime += frames
                player.scheduleFile(file, at: AVAudioTime(sampleTime: segmentTime, atRate: sampleRate), completionHandler: segmentCompletion)
            }
        }
        player.scheduleFile(file, at: AVAudioTime(sampleTime: segmentTime, atRate: sampleRate), completionHandler: segmentCompletion)
        segmentCompletion()
        player.prepare(withFrameCount: UInt32(frames))
        player.play()
        
        return looping
    }
}


extension LoopPlayer {
    
    func turnOn(index: String) {
        let volume = SettingsManager.getVolume(index: Int(index) ?? 100)
        guard volume > 0 else { return }
        
        if let item = fadeOutMap[index] {
            item.cancel()
        }
        
        let item = DispatchWorkItem {
            if let unitEQ = self.audioUnits[index] {
                let start = self.getVolume(unitEQ.globalGain)
                let coef = Float(1) - start / Float(100)
                
                for i in stride(from: Int(start), through: volume, by: 1) {
                    unitEQ.globalGain = self.setVolume(Float(i))
                    let time = TimeInterval(self.fadeSecs * coef / Float(100))
                    Thread.sleep(forTimeInterval: time)
                }
                
                if self.fadeInMap[index] != nil {
                    self.fadeInMap[index]?.cancel()
                    self.fadeInMap.removeValue(forKey: index)
                }
            }
        }
        
        if fadeInMap[index] == nil, audioUnits[index]?.globalGain != maxDb {
            fadeInMap[index] = item
            DispatchQueue.global().async(execute: item)
        }
    }
    
    func turnOff(index: String) {
        let volume = SettingsManager.getVolume(index: Int(index) ?? 100)
        guard volume > 0 else { return }
        
        if let item = fadeInMap[index] {
            item.cancel()
        }
        
        let item = DispatchWorkItem {
            if let unitEQ = self.audioUnits[index] {
                let start = self.getVolume(unitEQ.globalGain)
                let coef = start / Float(100)
                
                for i in stride(from: volume, through: 0, by: -1) {
                    unitEQ.globalGain = self.setVolume(Float(i))
                    let time = TimeInterval(self.fadeSecs * coef / Float(100))
                    Thread.sleep(forTimeInterval: time)
                }
                
                if self.fadeOutMap[index] != nil {
                    self.fadeOutMap[index]?.cancel()
                    self.fadeOutMap.removeValue(forKey: index)
                }
            }
        }
        
        if fadeOutMap[index] == nil, audioUnits[index]?.globalGain != minDb {
            fadeOutMap[index] = item
            DispatchQueue.global().async(execute: item)
        }
    }
    
    func updateVolue(index: String, value: Int) {
        let item = DispatchWorkItem {
            if let unitEQ = self.audioUnits[index] {
                unitEQ.globalGain = self.setVolume(Float(value))
            }
        }
        DispatchQueue.global().async(execute: item)
    }
    
    private func setVolume(_ value: Float) -> Float {
        
        if value < 1 {
            return minDb
        }
        
        if (value > 99) {
            return maxDb
        }
        
        return 48.0 * log10f(value / 100)
    }
    
    private func getVolume(_ value: Float) -> Float {
        
        if value == minDb {
            return 0
        }
        
        if value == maxDb {
            return 100
        }
        
        return powf(10.0, value / 48.0) * 100
    }
}
