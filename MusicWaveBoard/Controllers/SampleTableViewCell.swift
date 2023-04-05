//
//  SampleCell.swift
//  MusicWaveBoard
//
//  Created by Vitaliy Gribko on 26.03.2023.
//

import UIKit

class SampleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var sampleImageView: UIImageView!
    @IBOutlet weak var samplePlayImageView: UIImageView!
    @IBOutlet weak var sampleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let verticalSpace: CGFloat = 1.0
        self.contentView.frame = self.contentView.frame.inset(by: UIEdgeInsets(top: verticalSpace, left: 0, bottom: verticalSpace, right: 0))
    }
}
