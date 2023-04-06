//
//  SampleManager.swift
//  MusicWaveBoard
//
//  Created by Vitaliy Gribko on 30.03.2023.
//

import Foundation

class SampleManager {
    
    static func getTrackByKeyWords(words: String, index: Int) -> String {
        let keyWords = words.lowercased().components(separatedBy: " ")
        return findBestСoincidence(keyWords: keyWords)
    }
    
    static func getInstrumentLabel(index: Int) -> String {
        switch (index) {
        case 1..<7:
            return "Voc"
        case 7..<13:
            return "Drum"
        case 13..<19:
            return "Guit"
        default:
            return "Key"
        }
    }
    
    private static func findBestСoincidence(keyWords: [String]) -> String {
        var result = [String: Int]()
        
        LoopStorage.loopTags.forEach { (key: String, value: [String]) in
            keyWords.forEach { (word: String) in
                if (value.contains(word)) {
                    if var current = result[key] {
                        current += 1
                        result[key] = current
                    } else {
                        result[key] = 1
                    }
                }
            }
        }
        
        let maxСoincidenceNum = result.values.max()
        let maxСoincidence = result.first { (key: String, value: Int) in
            value == maxСoincidenceNum
        }?.key
        
        if let result = maxСoincidence {
            return result
        } else {
            let random = Int.random(in: 0..<LoopStorage.loopTags.count)
            let index = LoopStorage.loopTags.index(LoopStorage.loopTags.startIndex, offsetBy: random)
            return LoopStorage.loopTags.keys[index]
        }
    }
}
