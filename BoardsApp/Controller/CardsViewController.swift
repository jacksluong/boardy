//
//  CardsViewControllerProtocol.swift
//  BoardsApp
//
//  Created by Jacky Luong on 8/3/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit

import Foundation

class CardsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	// MARK: - Outlets
	
	@IBOutlet var tableView: UITableView! {
	   didSet {
		   tableView.delegate = self
		   tableView.dataSource = self
	   }
   }
	
	// MARK: - Properties
	
	var posts: [Post] = []
	var numHeaderRows: Int!
	private lazy var refreshControl = UIRefreshControl()
	
	// MARK: - Actions
	
	@objc func refresh(_ sender: Any) {
		let oldPosts = posts
		AppDelegate.loadDataFromParse(withCachePolicy: .networkOnly, caller: self)
		updateData()
		let newPosts = posts
		updateTableView(oldPosts: oldPosts, newPosts: newPosts)
		refreshControl.endRefreshing()
	}
	
	// MARK: - Initialization
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Refresh control
		refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
		tableView.addSubview(refreshControl)
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		// Dark/light mode
		if isDarkModeOn {
			view.backgroundColor = UIColor(red: 95.0/255, green: 95.0/255, blue: 95.0/255, alpha: 1)
		} else {
			view.backgroundColor = UIColor(red: 224.0/255, green: 224.0/255, blue: 224.0/255, alpha: 1)
		}
		colorBarButtonItems()
	}
	
	// MARK: - Table View
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return max(posts.count, 1) + numHeaderRows
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if posts.count == 0 {
			return tableView.dequeueReusableCell(withIdentifier: "nocards", for: indexPath)
		}
		
		let post = posts[indexPath.row - numHeaderRows]
		var card: CardTableViewCell
		if post.isPinned {
			card = tableView.dequeueReusableCell(withIdentifier: "pinnedcard", for: indexPath) as! CardTableViewCell
			card.post = post
			card.isInGroupPage = title == post.group
		} else {
			card = tableView.dequeueReusableCell(withIdentifier: post.type == .meeting ? "meetingcard" : "announcementcard", for: indexPath) as! CardTableViewCell
			card.post = post
		}
		
		card.layoutSubviews()
		
		return card
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard indexPath.row >= numHeaderRows else {
			return
		}
		
		tableView.deselectRow(at: indexPath, animated: false)
		let cardDetailVc = CardDetailTableViewController.cardDetailVc
		cardDetailVc.post = posts[indexPath.row - numHeaderRows]
		present(cardDetailVc, animated: true, completion: nil)
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return indexPath.row >= numHeaderRows
	}
	
	// MARK: - Swipe Actions
	
	func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let post = posts[indexPath.row - numHeaderRows]
		let pinnedPosts = UserDefaults.standard.string(forKey: "pinnedPosts")!
		let pinAction = UIContextualAction(style: .destructive, title: "") { (action, sourceView, completionHandler) in
			if post.isPinned {
				UserDefaults.standard.set(pinnedPosts.replacingOccurrences(of: post.postId + ";", with: ""), forKey: "pinnedPosts")
			} else {
				UserDefaults.standard.set(pinnedPosts + post.postId + ";", forKey: "pinnedPosts")
			}
			post.updateNotifications()
			Post.allPosts.sort(by: Comparators.selectedSortMethod)
			self.updateData()
			if let newIndex = self.posts.firstIndex(of: post) {
				tableView.beginUpdates()
				tableView.deleteRows(at: [indexPath], with: .fade)
				tableView.insertRows(at: [IndexPath(item: newIndex + self.numHeaderRows, section: 0)], with: .left)
				tableView.endUpdates()
			}
			
			print("\npinnedPosts: \(UserDefaults.standard.string(forKey: "pinnedPosts") ?? "")")
			completionHandler(true)
		}
		pinAction.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
		pinAction.image = UIImage(named: post.isPinned ? "star" : "star2")?.withRenderingMode(.alwaysOriginal)
		let swipeAction = UISwipeActionsConfiguration(actions: [pinAction])
		return swipeAction
	}
	
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		guard AppDelegate.administratorAccess else {
			return nil
		}
		
		let post = posts[indexPath.row - numHeaderRows]
		let hideAction = UIContextualAction(style: .normal, title: "") { (action, sourceView, completionHandler) in
			// Present confirmation alert controller...
			let noAction = AlertAction.cancel("No")
			let yesAction = AlertAction.normal(UIAlertAction(title: "Yes", style: .default) { _ in
				post.hidden = !post.hidden
				
				// -> ...present saving alert controller and attempt to save the change to Parse...
				let saving = UIAlertController(title: "Updating post in server...", message: nil, preferredStyle: .alert)

				self.present(saving, animated: true) {
					let pfObject = post.toPFObject()
					pfObject.saveInBackground { (success, error) in
						if success {
							saving.dismiss(animated: true) {
								// -> ...present the OK alert controller
								self.alert(title: "Post updated.", message: "", actions: [AlertAction.normal(UIAlertAction(title: "OK", style: .cancel) { _ in
									completionHandler(true)
									self.tableView.cellForRow(at: indexPath)?.layoutSubviews()
									})])
							}
						} else {
							print("Update error (for hiding/showing): \(error?.localizedDescription ?? "unknown error")")
							self.displayInNavigationBar(message: "Update failed.", color: UIColor(red: 0.8, green: 0, blue: 0, alpha: 1))
							saving.dismiss(animated: true)
							completionHandler(true)
						}
					}
				}
			})
			let actionText = post.hidden ? "show this post to" : "hide this post from"
			self.alert(title: "Confirmation", message: "Are you sure you want to \(actionText) all students?", actions: [noAction, yesAction])
		}
		hideAction.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
		hideAction.image = UIImage(named: post.hidden ? "show" : "hide")?.withRenderingMode(.alwaysOriginal)
		let swipeAction = UISwipeActionsConfiguration(actions: [hideAction])
		return swipeAction
	}
	
	// MARK: - Auxiliary
	
	func updateData() { // Must be overridden by each subclass in order to work properly
		let containsHiddenPosts = Post.allPosts.contains { Post.hiddenPosts.contains($0) }
		if AppDelegate.administratorAccess && !containsHiddenPosts {
			for post in Post.hiddenPosts {
				Post.allPosts.append(post, sortedBy: Comparators.selectedSortMethod)
			}
		} else if !AppDelegate.administratorAccess && containsHiddenPosts {
			Post.allPosts.removeAll { Post.hiddenPosts.contains($0) }
		}
	}
	
	/// Animates the insertion or deletion of rows based on the given previous and after states.
	func updateTableView(oldPosts: [Post], newPosts: [Post]) {
		var deleteRows: [IndexPath] = []
		for index in 0..<oldPosts.count {
			if !newPosts.contains(oldPosts[index]) {
				deleteRows.append(IndexPath(row: index + numHeaderRows, section: 0))
			}
		}
		
		var insertRows: [IndexPath] = []
		for index in 0..<newPosts.count {
			if !oldPosts.contains(newPosts[index]) {
				insertRows.append(IndexPath(row: index + numHeaderRows, section: 0))
			}
		}
		
		if oldPosts.count == 0 && newPosts.count != 0 {
			deleteRows.append(IndexPath(row: numHeaderRows, section: 0))
		} else if oldPosts.count != 0 && newPosts.count == 0 {
			insertRows.append(IndexPath(row: numHeaderRows, section: 0))
		}
		
		if insertRows.count != 0 || deleteRows.count != 0 {
			tableView.beginUpdates()
			tableView.deleteRows(at: deleteRows, with: .fade)
			tableView.insertRows(at: insertRows, with: .fade)
			tableView.endUpdates()
		} else {
			tableView.reloadData()
		}
	}
}
