//
//  SamplesViewController.swift
//  MusicWaveBoard
//
//  Created by Vitaliy Gribko on 17.09.2021.
//

import UIKit

class SamplesViewController: UITableViewController {
    
    var speechRecognizer = SpeechRecognizer()
    
    override func viewDidAppear(_ animated: Bool) {
        speechRecognizer.reset()
        speechRecognizer.transcribe()
        
        speechRecognizer.voiceHandler = { (message) -> Void in
            let dialogMessage = UIAlertController(title: "Confirm", message: message, preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        speechRecognizer.stopTranscribing()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = nil
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 24
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SamplesCell", for: indexPath) as! SampleTableViewCell
        
        cell.contentView.layer.cornerRadius = cell.contentView.frame.height / 4
        
        return cell
    }
}
