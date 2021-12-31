//
//  HomeTableViewController.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/23/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//
//  CURRENTLY NOT INCLUDED IN APP, BUT CAN ADD ANYTIME
//

import UIKit

class HomeTableViewController: UITableViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	
	// MARK: - Outlets
	
	@IBOutlet var newGroupImageView: UIImageView!
	@IBOutlet var newGroupLabel: UILabel!
	
	@IBOutlet var newPostsCollectionView: UICollectionView!
	@IBOutlet var recentlyUpdatedCollectionView: UICollectionView!
	@IBOutlet var pinnedPostsCollectionView: UICollectionView!
	
	// MARK: - Actions
	
	// MARK: - Initialization
	
	private var newPosts: [Post] = []
	private var recentlyUpdatedPosts: [Post] = []
	private var pinnedPosts: [Post] = []
	
	private let sectionInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = 160
	}
	
	override func viewWillAppear(_ animated: Bool) {
		for post in CardsViewController.allPosts {
			if SimpleDate.now < post.creationTime.forward(by: 1, .day) {
				newPosts.append(post)
			}
			if SimpleDate.now < post.timeLastUpdated.forward(by: 1, .day) {
				recentlyUpdatedPosts.append(post)
			}
			if post.isPinned {
				pinnedPosts.append(post)
			}
		}
		newPosts.sort { $1.creationTime < $0.creationTime }
		newPosts = [Post](newPosts.prefix(4))
		recentlyUpdatedPosts.sort { $1.timeLastUpdated < $0.timeLastUpdated }
		recentlyUpdatedPosts = [Post](recentlyUpdatedPosts.prefix(4))
		
		if AllGroupsTableViewController.allGroups.count > 1 { // has something other than administration
			var newestGroup = AllGroupsTableViewController.allGroups[0]
			for index in 1..<AllGroupsTableViewController.allGroups.count {
				if newestGroup.creationTime < AllGroupsTableViewController.allGroups[index].creationTime {
					newestGroup = AllGroupsTableViewController.allGroups[index]
				}
			}
			if SimpleDate.now < newestGroup.creationTime.forward(by: 2, .day) {
				newGroupLabel.text = newestGroup.name
				if let data = newestGroup.image {
					data.getDataInBackground(block: { (imageData, error) in
						if let imageData = imageData {
							self.newGroupImageView.image = UIImage(data: imageData)
						}
					})
				}
			}
		}
		
		tableView.reloadData()
	}
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		var sections = 0
		if newPosts.count > 0 { sections += 1 }
		if recentlyUpdatedPosts.count > 0 { sections += 1 }
		if pinnedPosts.count > 0 { sections += 1 }
		for group in AllGroupsTableViewController.allGroups {
			if SimpleDate.now < group.creationTime.forward(by: 2, .day) {
				sections += 1
				break
			}
		}
		return sections
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == 0 {
			return 250
		} else if indexPath.section == 1 {
			return newPostsCollectionView.frame.height + 20
		} else if indexPath.section == 2 {
			return recentlyUpdatedCollectionView.frame.height + 20
		} else {
			return pinnedPostsCollectionView.frame.height + 20
			}
	}
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return section == 0 ? 0 : 20
	} // √
	
	// MARK: - Collection view data source
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if collectionView == newPostsCollectionView {
			return newPosts.count
		} else if collectionView == recentlyUpdatedCollectionView {
			return recentlyUpdatedPosts.count
		} else {
			return pinnedPosts.count
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let itemsPerRow: CGFloat = 2
		let paddingSpace = sectionInsets.left * (itemsPerRow + 1) // "columns" of padding per row
		let availableWidth = view.frame.width - paddingSpace
		let widthPerItem = availableWidth / itemsPerRow
		
		return CGSize(width: widthPerItem, height: widthPerItem)
	} // √
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return sectionInsets
	} // √
	
	// 4
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return sectionInsets.left
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "postcell", for: indexPath) as! CardCollectionViewCell
		var post: Post
		if collectionView == newPostsCollectionView {
			post = newPosts[indexPath.row]
		} else if collectionView == recentlyUpdatedCollectionView {
			post = recentlyUpdatedPosts[indexPath.row]
		} else {
			post = pinnedPosts[indexPath.row]
		}
		
		cell.groupNameLabel.text = post.group
		cell.titleLabel.text = post.titleDisplay
		cell.timeLabel.text = post.timeDisplay
		if let data = post.image {
			data.getDataInBackground(block: { (imageData, error) in
				if let imageData = imageData {
					cell.postImageView.image = UIImage(data: imageData)
				}
			})
		}
		
		return cell
	} // √
	
}
