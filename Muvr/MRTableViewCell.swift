//
//  MRTableViewCell.swift
//  Muvr
//
//  Created by Duc Hoang on 26/11/2015.
//  Copyright © 2015 Muvr. All rights reserved.
//

import UIKit

class MRTableViewCell: UITableViewCell {
    
    @IBOutlet weak var exerciseIdLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
