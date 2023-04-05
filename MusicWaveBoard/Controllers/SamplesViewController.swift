//
//  SamplesViewController.swift
//  MusicWaveBoard
//
//  Created by Vitaliy Gribko on 17.09.2021.
//

import UIKit
import AVFoundation

class SamplesViewController: UITableViewController {
    
    private let sampleManager = SampleManager()
    private let speechRecognizer = SpeechRecognizer()
    private var audioPlayer = AVAudioPlayer()
    
    private var lastRecCell: SampleTableViewCell? = nil
    private var lastPlayCell: SampleTableViewCell? = nil
    
    private let defaultHint = "Long tap and then speak to change..."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = nil
        
        let press = UITapGestureRecognizer(target: self, action: #selector(handlePress(sender:)))
        tableView.addGestureRecognizer(press)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        tableView.addGestureRecognizer(longPress)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if (lastRecCell != nil) {
            stopVoiceRecognizer()
        }
        
        if (lastPlayCell != nil) {
            stopSamplePlayback()
        }
    }
    
    // MARK: - Table view click events
    
    @objc private func handlePress(sender: UITapGestureRecognizer) {
        let touchPoint = sender.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: touchPoint) {
            guard lastRecCell == nil else { return }
            
            if (lastPlayCell?.indexPath?.row == indexPath.row) {
                stopSamplePlayback()
                return
            } else {
                guard lastPlayCell == nil else { return }
            }
            
            let index = indexPath.row + 1
            
            guard let track = SettingsManager.getTrack(index: index) else { return }
            guard let soundFileURL = Bundle.main.url(
                forResource: track.track,
                withExtension: "wav",
                subdirectory: "Samples"
            ) else {
                return
            }
            
            do {
                startPlayback()
                
                audioPlayer = try AVAudioPlayer(contentsOf: soundFileURL)
                audioPlayer.delegate = self as AVAudioPlayerDelegate
                
                audioPlayer.prepareToPlay()
                audioPlayer.play()
                
                let cell = tableView.cellForRow(at: indexPath) as! SampleTableViewCell
                cell.samplePlayImageView.image = UIImage(named: "pause")
                
                lastPlayCell = cell
            }
            catch {}
        }
    }
    
    @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                guard lastRecCell == nil else { return }
                guard lastPlayCell == nil else { return }
                
                let index = indexPath.row + 1
                let cell = tableView.cellForRow(at: indexPath) as! SampleTableViewCell
                lastRecCell = cell
                
                cell.contentView.backgroundColor = UIColor.red
                var words: String = ""
                
                speechRecognizer.reset()
                speechRecognizer.transcribe()
                
                speechRecognizer.voiceHandler = { (message) -> Void in
                    let text = String.localizedStringWithFormat("%.2d. %@", index, message)
                    cell.sampleLabel.text = text
                    
                    words = message
                }
                
                Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
                    if (self.lastRecCell == nil) {
                        return
                    }
                    
                    self.stopVoiceRecognizer()
                    guard !words.isEmpty else { return }
                    
                    let track = self.sampleManager.getTrackByKeyWords(words: words, index: index)
                    SettingsManager.setTrack(index: index, track: track, keyWords: words)
                    
                    cell.samplePlayImageView.isHidden = false
                }
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 24
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SamplesCell", for: indexPath) as! SampleTableViewCell
        
        cell.contentView.layer.cornerRadius = cell.contentView.frame.height / 8
        cell.contentView.backgroundColor = UIColor.systemGray4
        
        let index = indexPath.row + 1
        let text = String.localizedStringWithFormat("%.2d. %@", index, defaultHint)
        cell.sampleLabel.text = text
        
        cell.samplePlayImageView.alpha = 0.5
        if let track = SettingsManager.getTrack(index: index) {
            let text = String.localizedStringWithFormat("%.2d. %@", index, track.keyWords)
            cell.sampleLabel.text = text
            
            cell.samplePlayImageView.isHidden = false
        } else {
            cell.samplePlayImageView.isHidden = true
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Reset"
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard lastRecCell == nil else { return }
            guard lastPlayCell == nil else { return }
            
            let index = indexPath.row + 1
            let text = String.localizedStringWithFormat("%.2d. %@", index, defaultHint)
            
            let cell = tableView.cellForRow(at: indexPath) as! SampleTableViewCell
            cell.sampleLabel.text = text
            
            cell.samplePlayImageView.isHidden = true
            
            SettingsManager.clearTrack(index: index)
        }
    }
    
    // MARK: - Working functions
    private func startPlayback() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setMode(AVAudioSession.Mode.default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        }
        catch {}
    }
    
    private func stopVoiceRecognizer() {
        speechRecognizer.stopTranscribing()
        lastRecCell?.contentView.backgroundColor = UIColor.systemGray4
        lastRecCell = nil
    }
    
    private func stopSamplePlayback() {
        if (audioPlayer.isPlaying) {
            audioPlayer.stop()
        }
        
        lastPlayCell?.samplePlayImageView.image = UIImage(named: "play")
        lastPlayCell = nil
    }
}

extension SamplesViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopSamplePlayback()
    }
}

extension UIResponder {
    func next<U: UIResponder>(of type: U.Type = U.self) -> U? {
        return self.next.flatMap({ $0 as? U ?? $0.next() })
    }
}

extension UITableViewCell {
    var tableView: UITableView? {
        return self.next(of: UITableView.self)
    }
    
    var indexPath: IndexPath? {
        return self.tableView?.indexPath(for: self)
    }
}
