//
//  SamplesViewController.swift
//  MusicWaveBoard
//
//  Created by Vitaliy Gribko on 17.09.2021.
//

import UIKit

class SamplesViewController: UITableViewController {
    
    private let sampleManager = SampleManager()
    private let speechRecognizer = SpeechRecognizer()
    
    private var lastActiveCell: SampleTableViewCell? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = nil
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        tableView.addGestureRecognizer(longPress)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if (lastActiveCell != nil) {
            stopVoiceRecognizer()
        }
    }
    
    // MARK: - Table view click events
    
    @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                if (lastActiveCell != nil) {
                    return
                }
                
                let cell = tableView.cellForRow(at: indexPath) as! SampleTableViewCell
                lastActiveCell = cell
                let index = indexPath.row + 1
                
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
                    if (self.lastActiveCell == nil) {
                        return
                    }
                    
                    self.stopVoiceRecognizer()
                    self.sampleManager.setKeyWords(words: words, for: index)
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
        let text = String.localizedStringWithFormat("%.2d. (Holding and then speak to change)", index)
        cell.sampleLabel.text = text
        
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
            if (lastActiveCell != nil) {
                return
            }
            
            let index = indexPath.row + 1
            let text = String.localizedStringWithFormat("%.2d. (Holding and then speak to change)", index)
            
            let cell = tableView.cellForRow(at: indexPath) as! SampleTableViewCell
            cell.sampleLabel.text = text
        }
    }
    
    // MARK: - Working functions
    private func stopVoiceRecognizer() {
        speechRecognizer.stopTranscribing()
        lastActiveCell?.contentView.backgroundColor = UIColor.systemGray4
        lastActiveCell = nil
    }
}
