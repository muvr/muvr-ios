//
//  MRTableViewCell.swift
//  Muvr
//
//  Copyright © 2015 Muvr. All rights reserved.
//

import UIKit

class MRExerciseViewCell: UITableViewCell {
    
    @IBOutlet weak var exerciseIdLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var verifiedImgView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private var initWidth: CGFloat? = nil
    
    override func layoutSubviews() {
        if (initWidth == nil) {
            initWidth = self.bounds.size.width
        }
        self.bounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, initWidth! - 40, self.bounds.size.height)
        super.layoutSubviews()
    }

}
