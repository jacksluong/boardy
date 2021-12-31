//
//  CardDetailTableViewController.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/18/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit

class CardDetailTableViewController: UITableViewController {
	
	// MARK: - Outlets
	
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var postImageView: UIImageView!
	@IBOutlet var typeImageView: UIImageView!
	@IBOutlet var imageInfoLabel: UILabel!
	
	@IBOutlet var groupLabel: UILabel!
	@IBOutlet var timeLabel: UILabel!
	@IBOutlet var locationLabel: UILabel!
	@IBOutlet var timeStack: UIStackView!
	@IBOutlet var locationStack: UIStackView!
	
	@IBOutlet var descriptionLabel: UILabel!

	// MARK: - Properties
	
	var post: Post!
	static var cardDetailVc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "cardDetail") as! CardDetailTableViewController

	// MARK: - Actions
	
	@IBAction func xTapped(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}
	
	// MARK: - Initialization
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = 100
	}
	
	override func viewWillAppear(_ animated: Bool) {
		titleLabel.text = post.titleDisplay
		postImageView.image = UIImage()
		if let image = post.loadedImage {
			imageInfoLabel.isHidden = false
			postImageView.image = image
		} else {
			imageInfoLabel.isHidden = true
		}
		typeImageView.image = UIImage(named: "\(post.type)")
		tableView.reloadData()
		
		groupLabel.text = post.group
		if post.type == .announcement {
			locationStack.isHidden = true
			timeLabel.text = "Post expires on \(post.time.calendarTime.month)/" + "\(post.time.calendarTime.year)".suffix(2)
		} else {
			locationStack.isHidden = false
			locationLabel.text = post.location
			timeLabel.text = post.timeDisplay + ((post.type == .meeting && post.time.clockTime == (0,0)) ? " 12:00 AM" : "")
		}
		
		descriptionLabel.text = post.description
	}

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.row == 0 {
			return post.image == nil ? 165 : 242
		} else {
			return UITableView.automaticDimension
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		if indexPath.row == 0, let image = post.loadedImage {
			var y: Int
			if let keyWindow = UIApplication.shared.keyWindow, keyWindow.safeAreaInsets.bottom > 0 {
				y = Int(UIScreen.main.bounds.height) - (83 + 80)
			} else {
				y = Int(UIScreen.main.bounds.height) - (49 + 80)
			}
			
			// Show full image
			let imageZoomView = ImageZoomView(frame: CGRect(x: 25, y: 40, width: Int(UIScreen.main.bounds.width) - 50, height: y), image: image)
			self.tableView.addSubview(imageZoomView)
			self.tableView.bringSubviewToFront(imageZoomView)
		}
	}

}
