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

func loopWholeFile(file: AVAudioFile, player: AVAudioPlayerNode) -> Latch {
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

class LoopPlayer {
    
    var audioPlayers = [String: AVAudioPlayerNode]()
    var audioUnits = [String: AVAudioUnitEQ]()

    private var audioFiles = [String: AVAudioFile]()
    
    private var audioEngine = AVAudioEngine()
    
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
            
            audioUnits[key]!.globalGain = -96
        }
    }
}
