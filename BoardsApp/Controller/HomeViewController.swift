//
//  HomeViewController.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/21/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit
import CoreData
import Parse

class HomeViewController: CardsViewController {

	// MARK: - Outlets
	
	@IBOutlet var segmentedControl: UISegmentedControl! {
		didSet {
			segmentedControl.selectedSegmentIndex = 0
		}
	}
	@IBOutlet var collectionLabel: UILabel!
	
	@IBOutlet var walkthroughView: WalkthroughView!
	
	// MARK: - Properties
	
	private var selectedCollection: CardCollection = .all
	private var animated = false
	
	private var lastContentOffset: CGFloat = 0
	private var scrollLock = false
	
	// MARK: - Actions
	
	@IBAction func segmentSelected(_ sender: UISegmentedControl) {
		tableView.setEditing(false, animated: false)
		if let newCollection = CardCollection(rawValue: sender.selectedSegmentIndex) {
			selectedCollection = newCollection
		}
		
		// Segmented control
		scrollLock = true
		segmentedControl.layer.removeAllAnimations()
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.decreaseSegmentedControlAlpha), object: nil)
		segmentedControl.alpha = 0.95
		self.perform(#selector(self.decreaseSegmentedControlAlpha), with: nil, afterDelay: 1.8)
		
		// Table view
		let oldPosts = posts
		updateData()
		updateTableView(oldPosts: oldPosts, newPosts: posts)
		
		// Collection label
		collectionLabel.layer.removeAllAnimations()
		collectionLabel.alpha = 1
		collectionLabel.transform = .identity
		
		var title = "\(selectedCollection)".capitalized
		if selectedCollection == .all {
			title += " Posts"
		} else if selectedCollection == .starred {
			title += " Groups"
		}
		collectionLabel.text = title
		
		UIView.animate(withDuration: 0.3, delay: 1.8, options: [.curveEaseOut], animations: {
			self.collectionLabel.alpha = 0
			self.collectionLabel.transform = CGAffineTransform(translationX: 0, y: 30)
		})
	}
	
	@objc func decreaseSegmentedControlAlpha() {
		UIView.animate(withDuration: 0.25, animations: {
			self.segmentedControl.alpha = 0.35
		})
	}
	
	// MARK: - Scroll View
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		scrollLock = false
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let scrollViewHeight = scrollView.frame.size.height;
		let scrollContentSizeHeight = scrollView.contentSize.height;
		let scrollOffset = scrollView.contentOffset.y;
		
		// Make sure it's not above the top or below the bottom in a "bounce back" animation
		guard scrollOffset > -10 && (scrollOffset + scrollViewHeight) < scrollContentSizeHeight + 90 && !scrollLock else {
			return
		}
		
		var scrollDirection: UIAccessibilityScrollDirection = .previous
	
		if lastContentOffset > scrollView.contentOffset.y {
			scrollDirection = .up
		} else if lastContentOffset < scrollView.contentOffset.y {
			scrollDirection = .down
		}
		
		lastContentOffset = scrollView.contentOffset.y
		
		if scrollDirection == .up {
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.decreaseSegmentedControlAlpha), object: nil)
			UIView.animate(withDuration: 0.25, animations: {
				self.segmentedControl.alpha = 0.95
			}, completion: { _ in
				self.perform(#selector(self.decreaseSegmentedControlAlpha), with: nil, afterDelay: 1.8)
			})
		} else if scrollDirection == .down {
			decreaseSegmentedControlAlpha()
		}
	}
	
	// MARK: - Initialization
	
	override func viewDidLoad() {
		super.viewDidLoad()
		numHeaderRows = 0
		
		// Visual
		tableView.contentInsetAdjustmentBehavior = .never
		tableView.rowHeight = UITableView.automaticDimension
		tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 90, right: 0)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		navigationItem.titleView = nil
		updateData()
		tableView.reloadData()
		
		// Collection label
		var title = "\(selectedCollection)".capitalized
		if selectedCollection == .all {
			title += " Posts"
		} else if selectedCollection == .starred {
			title += " Groups"
		}
		collectionLabel.text = title
		collectionLabel.alpha = 1
		collectionLabel.transform = .identity
		collectionLabel.layer.removeAllAnimations()
		segmentedControl.alpha = 0.95
		segmentedControl.layer.removeAllAnimations()
		UIView.animate(withDuration: 0.3, delay: 1.8, options: [.curveEaseOut], animations: {
			self.segmentedControl.alpha = 0.35
			self.collectionLabel.alpha = 0
			self.collectionLabel.transform = CGAffineTransform(translationX: 0, y: 30)
		})
	}
	
	override func viewDidAppear(_ animated: Bool) {
		if !UserDefaults.standard.bool(forKey: "walkthroughed") {
			navigationController?.view.addSubview(walkthroughView)
			walkthroughView.isHidden = false
			walkthroughView.alpha = 0
			UIView.animate(withDuration: 0.4, animations: {
				self.walkthroughView.alpha = 1
			})
		} else {
			walkthroughView.removeFromSuperview()
		}
	}
	
	// MARK: - Table View
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if cell.reuseIdentifier == "nocards" { return }
		if !animated {
			tableView.isUserInteractionEnabled = false
			
			cell.alpha = 0
			let post = posts[indexPath.row]
			cell.transform = CGAffineTransform(translationX: post.isPinned ? 500 : 0, y: post.isPinned ? 0 : 25)
			UIView.animate(withDuration: 0.4, delay: Double(indexPath.row) * 0.125 + 0.3, options: [], animations: {
				cell.transform = .identity
				cell.alpha = 1
			}) { _ in
				if indexPath.row == tableView.visibleCells.count - 1 {
					self.animated = true
					self.tableView.isUserInteractionEnabled = true
				}
			}
		}
	}
	
	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		if posts.count == 0 { return 150 }
		switch posts[indexPath.row].type {
		case .announcement, .event: return 135
		case .meeting: return 70
		}
	}
	
	// MARK: - Updates
	
	override func updateData() {
		super.updateData()
		switch selectedCollection {
		case .all:
			posts = Post.allPosts
		case .announcements:
			posts = Post.allPosts.filter { $0.type == .announcement && $0.group != "Administration" }
		case .events:
			posts = Post.allPosts.filter { $0.type == .event && $0.group != "Administration" }
		case .meetings:
			posts = Post.allPosts.filter { $0.type == .meeting && $0.group != "Administration" }
		case .administration:
			posts = Post.allPosts.filter { $0.group == "Administration" }
		case .starred:
			posts = Post.allPosts.filter { post in
				AllGroupsTableViewController.starredGroups.contains(where: { $0.name == post.group })
			}
		}
	}
	
}

enum CardCollection: Int {
	case all = 0
	case announcements
	case events
	case meetings
	case administration
	case starred
}
