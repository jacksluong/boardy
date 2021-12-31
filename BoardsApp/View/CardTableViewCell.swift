//
//  CardTableViewCell.swift
//  BoardsApp
//
//  Created by Jacky Luong on 6/26/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit

class CardTableViewCell: UITableViewCell {
	
	// MARK: - Outlets
	
	@IBOutlet var cardView: UIView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var label1: UILabel!
	@IBOutlet var label2: UILabel!
	@IBOutlet var descriptionLabel: UILabel?
	@IBOutlet var typeImageView: UIImageView?
	var animated = false
	
	// MARK: - Properties
	
	var post: Post!
	var isInGroupPage = false
	
	// MARK: - Initialization
	
    override func awakeFromNib() {
        super.awakeFromNib()
		
        // Initialization code
		cardView.layer.masksToBounds = true
		descriptionLabel?.numberOfLines = 4
	}
	
	override func layoutSubviews() {
		// Update labels
		var labels: [String]
		if post.isPinned {
			titleLabel.text = (!isInGroupPage ? "\(post.group): " : "") + post.titleDisplay
			let info = post.timeDisplay.components(separatedBy: " ")
			switch post.type {
			case .announcement:
				labels = [info[0], info[2]]
			case .event:
				labels = [info[0]]
				if info.count > 1 {
					labels.append("\(info[1]) \(info[2])")
				}
			case .meeting:
				labels = [info[0], "\(info[1]) \(info[2])"]
			}
		} else {
			titleLabel.text = post.titleDisplay
			typeImageView?.image = UIImage(named: "\(post.type)")
			labels = [post.group, post.timeDisplay]
		}
		if labels.count == 2 {
			label1.text = labels[0]
			label2.text = labels[1]
			label2.isHidden = false
		} else {
			label1.text = labels[0]
			label2.isHidden = true
		}
		
		// Update colors
		if post.isPinned {
			titleLabel.alpha = SimpleDate.now < post.time ? 1 : 0.65
			cardView.backgroundColor = UIColor(red: 250.0/255, green: 225.0/255, blue: 0, alpha: 1)
			titleLabel.backgroundColor = UIColor(red: 231.0/255, green: 208.0/255, blue: 113.0/255, alpha: 1)
			label1.backgroundColor = UIColor(white: 0, alpha: 0)
			label2.backgroundColor = UIColor(white: 0, alpha: 0)
		} else {
			if SimpleDate.now < post.time {
				label1.backgroundColor = UIColor(red: 29.0/255, green: 39.0/255, blue: 49.0/255, alpha: 1)
				label2.backgroundColor = UIColor(red: 29.0/255, green: 39.0/255, blue: 49.0/255, alpha: 1)
			} else {
				label1.backgroundColor = UIColor(red: 96.0/255, green: 132.0/255, blue: 162.0/255, alpha: 1)
				label2.backgroundColor = UIColor(red: 96.0/255, green: 132.0/255, blue: 162.0/255, alpha: 1)
			}
			switch post.type {
			case .announcement:
				cardView.backgroundColor = UIColor(red: 19.0/255, green: 110.0/255, blue: 171.0/255, alpha: 1)
			case .event:
				cardView.backgroundColor = UIColor(red: 50.0/255, green: 140.0/255, blue: 193.0/255, alpha: 1)
			case .meeting:
				cardView.backgroundColor = UIColor(red: 50.0/255, green: 176.0/255, blue: 206.0/255, alpha: 1)
			}
		}
		if post.hidden {
			cardView.backgroundColor = UIColor(red: 0.65, green: 0, blue: 0, alpha: 1)
			if post.isPinned {
				titleLabel.backgroundColor = UIColor(red: 0.65, green: 0, blue: 0, alpha: 1)
			}
		}
		cardView.alpha = SimpleDate.now < post.time ? 1 : 0.65
		descriptionLabel?.text = post.description
		
		layer.shadowOpacity = 0.45
		layer.shadowOffset = CGSize(width: 0, height: 6)
		layer.shadowRadius = 2.5
		
		super.layoutSubviews()
	}

}
