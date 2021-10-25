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
    
    func initDemo() {
        
        for (key, value) in LoopStorage.loopNames {
            guard let filePath = Bundle.main.path(forResource: value, ofType: "wav", inDirectory: "Loops") else { continue }
            
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
            try audioEngine.start()
        } catch {
            print(error)
        }
    }
    
    func start() {
        
        for (key, _) in LoopStorage.loopNames {
            
            guard audioPlayers[key] != nil, audioUnits[key] != nil, audioFiles[key] != nil else { continue }
            
            let looping = loopWholeFile(file: audioFiles[key]!, player: audioPlayers[key]!)
            looping.value = true
            
            audioUnits[key]!.globalGain = minDb
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

    func turnOn(piece: String) {
        
        if let item = fadeOutMap[piece] {
            item.cancel()
        }
        
        let item = DispatchWorkItem {
            if let unitEQ = self.audioUnits[piece] {
                let start = self.getVolume(unitEQ.globalGain)
                let coef = Float(1) - start / Float(100)
                
                for i in stride(from: start, through: 100, by: 1) {
                    unitEQ.globalGain = self.setVolume(Float(i))
                    let time = TimeInterval(self.fadeSecs * coef / Float(100))
                    Thread.sleep(forTimeInterval: time)
                }
                
                if self.fadeInMap[piece] != nil {
                    self.fadeInMap[piece]?.cancel()
                    self.fadeInMap.removeValue(forKey: piece)
                }
            }
        }
        
        if fadeInMap[piece] == nil, audioUnits[piece]?.globalGain != maxDb {
            fadeInMap[piece] = item
            DispatchQueue.global().async(execute: item)
        }
    }
    
    func turnOff(piece: String) {
        
        if let item = fadeInMap[piece] {
            item.cancel()
        }
        
        let item = DispatchWorkItem {
            if let unitEQ = self.audioUnits[piece] {
                let start = self.getVolume(unitEQ.globalGain)
                let coef = start / Float(100)
                
                for i in stride(from: start, through: 0, by: -1) {
                    unitEQ.globalGain = self.setVolume(Float(i))
                    let time = TimeInterval(self.fadeSecs * coef / Float(100))
                    Thread.sleep(forTimeInterval: time)
                }
                
                if self.fadeOutMap[piece] != nil {
                    self.fadeOutMap[piece]?.cancel()
                    self.fadeOutMap.removeValue(forKey: piece)
                }
            }
        }
        
        if fadeOutMap[piece] == nil, audioUnits[piece]?.globalGain != minDb {
            fadeOutMap[piece] = item
            DispatchQueue.global().async(execute: item)
        }
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
