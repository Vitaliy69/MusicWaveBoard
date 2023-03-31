//
//  SamplesViewController.swift
//  MusicWaveBoard
//
//  Created by Vitaliy Gribko on 17.09.2021.
//

import UIKit

class SamplesViewController: UITableViewController {
    
    let sampleManager = SampleManager()
    let speechRecognizer = SpeechRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = nil
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        tableView.addGestureRecognizer(longPress)
    }
    
    // MARK: - Table view click events
    
    @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                let cell = tableView.cellForRow(at: indexPath) as! SampleTableViewCell
                let index = indexPath.row + 1
                
                let backgroundColor = cell.contentView.backgroundColor
                cell.contentView.backgroundColor = UIColor.blue
                var words: String = ""
                
                speechRecognizer.reset()
                speechRecognizer.transcribe()
                
                speechRecognizer.voiceHandler = { (message) -> Void in
                    let text = String.localizedStringWithFormat("%.2d. %@", index, message)
                    cell.sampleLabel.text = text
                    
                    words = message
                }
                
                Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
                    self.speechRecognizer.stopTranscribing()
                    cell.contentView.backgroundColor = backgroundColor
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
            let index = indexPath.row + 1
            let text = String.localizedStringWithFormat("%.2d. (Holding and then speak to change)", index)
            
            let cell = tableView.cellForRow(at: indexPath) as! SampleTableViewCell
            cell.sampleLabel.text = text
        }
    }
}
