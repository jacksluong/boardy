//
//  GroupHeaderTableViewCell.swift
//
//  Created by Jacky Luong on 7/5/19.
//

import UIKit

class GroupHeaderTableViewCell: UITableViewCell {
	
	// MARK: - Outlets
	
	@IBOutlet var groupImageView: UIImageView!
	@IBOutlet var imageViewContainer: UIView!
	@IBOutlet var descriptionLabel: UILabel!
	@IBOutlet var emailButton: UIButton!
	@IBOutlet var topConstraint: NSLayoutConstraint!
	@IBOutlet var imageHeightConstraint: NSLayoutConstraint!
	@IBOutlet var additionalSpaceView: UIView!
	
	// MARK: - Actions
	
	@IBAction func emailButtonTapped(_ sender: Any) {
		if let email = emailButton.titleLabel?.text {
			if let url = URL(string: "mailto:\(email)") {
				if #available(iOS 10.0, *) {
					print("Email button clicked")
					UIApplication.shared.open(url)
				} else {
					print("Email button clicked")
					UIApplication.shared.openURL(url)
				}
			}
		}
	}
	
}
