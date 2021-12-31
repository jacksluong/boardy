//
//  CardCollectionViewCell.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/23/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit

class CardCollectionViewCell: UICollectionViewCell {
	
	@IBOutlet var groupNameLabel: UILabel!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var timeLabel: UILabel!
	@IBOutlet var postImageView: UIImageView!
	
    override func awakeFromNib() {
        super.awakeFromNib()
	}

}
