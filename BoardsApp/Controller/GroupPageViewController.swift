//
//  GroupPageViewController.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/7/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit
import Floaty
import Parse

class GroupPageViewController: CardsViewController {
	
	// MARK: - Outlets
	
	@IBOutlet var starButton: UIBarButtonItem!
	@IBOutlet var floatingButton: Floaty! {
		didSet {
			floatingButton.openAnimationType = .pop
			floatingButton.sticky = true
		}
	}
	@IBOutlet var floatyTapGesture: UITapGestureRecognizer!
	@IBOutlet var longPressFloatyGesture: UILongPressGestureRecognizer!
	
	// MARK: - Properties
	
	var group: Group!
	var updateAtIndex = -1
	var unlocked = false
	var appearedFirstTime = false
	private lazy var refreshControl = UIRefreshControl()
	
	// MARK: - Actions
	
	@IBAction func floatingButtonTapped(_ sender: Any) {
		// Three failed attempts within 5 minutes will trigger a lock for two hours
		var failedAttempts = UserDefaults.standard.dictionary(forKey: "failedAttempts") as? [String : [[Int]]] ?? [:]
		var theseAttempts: [[Int]] = [] // [times of three previous attempts, oldest first, and the last time the lock was triggered]
		if let previousAttempts = failedAttempts[group.groupId] {
			theseAttempts = previousAttempts
		}
		if theseAttempts.count == 4 && SimpleDate.now < SimpleDate(from: theseAttempts[3]).forward(by: 2, .hour) {
			alert(title: "Locked", message: "You may not currently attempt to gain access to this group.", actions: [])
			return
		}
		
		// Prompt for password
		let cancelAction = AlertAction.normal(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		let okAction = AlertAction.withTextField(title: "OK", style: .default, checkFor: group.password, matchHandler: {
			self.unlocked = true
			self.floatyTapGesture.isEnabled = false
			self.addNormalFloatingButtonItems()
			self.alert(title: "Permissions Granted", message: "Swipe left/right on a post for actions. Tap the button on the bottom right for more actions.", actions: [])
			self.floatingButton.buttonImage = UIImage(named: "triple dots")
		}, noMatchHandler: {
			var message = ""
			let now = SimpleDate.now.arrayForm
			if theseAttempts.count < 3 {
				theseAttempts.append(now)
			} else {
				theseAttempts.insert(now, at: 3)
				theseAttempts.removeFirst()
			}
			if theseAttempts.count >= 3 && SimpleDate.now < SimpleDate(from: theseAttempts[0]).forward(by: 10, .minute) {
				// Trigger lock
				if theseAttempts.count == 4 {
					theseAttempts.removeLast()
				}
				theseAttempts.append(now)
				message += "You cannot make another attempt for two hours."
			}
			failedAttempts[self.group.groupId] = theseAttempts
			UserDefaults.standard.set(failedAttempts, forKey: "failedAttempts")
			self.alert(title: "Incorrect Password", message: message, actions: [])
		})
		
		alert(title: "Password for \(group.name)", message: "The group password will give you permission to post and edit information.", actions: [cancelAction, okAction], textFieldPlaceholder: "Password")
	}
	
	@IBAction func starButtonTapped(_ sender: UIBarButtonItem) {
		if let starredGroups = UserDefaults.standard.string(forKey: "starredGroups") {
			if starredGroups.contains(group.groupId) {
				UserDefaults.standard.set(starredGroups.replacingOccurrences(of: group.groupId + ";", with: ""), forKey: "starredGroups")
					sender.image = UIImage(named: "star")
			} else {
				UserDefaults.standard.set(starredGroups + group.groupId + ";", forKey: "starredGroups")
				sender.image = UIImage(named: "star2")
			}
			print("starredGroups: \(UserDefaults.standard.string(forKey: "starredGroups") ?? "")\n")
		}
	}
	
	@IBAction func resetAdminPassword(_ sender: UILongPressGestureRecognizer) {
		guard floatingButton.items.count < 5 && sender.state == .began else {
			return
		}
		floatingButton.addItem("Reset password", icon: UIImage(named: "warning")) { item in
			let noAction = AlertAction.cancel("No")
			let yesAction = AlertAction.normal(UIAlertAction(title: "Yes", style: .default) { _ in
				self.group.generatePassword(saveToParse: true)
				self.alert(title: "Password Reset", message: "The new admin password is \"\(self.group.password)\".", actions: [])
			})
			self.alert(title: "Are you sure you want to reset the admin password?", message: "", actions: [noAction, yesAction])
		}
		longPressFloatyGesture.isEnabled = false
	}
	
	// MARK: - Initialization
	
	override func viewDidLoad() {
		super.viewDidLoad()
		numHeaderRows = 1
		
		PostFormTableViewController.postFormVc.groupPageVc = self
		GroupFormTableViewController.groupFormVc.groupPageVc = self
		
		tableView.estimatedRowHeight = 75
		tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 85, right: 0)
		
		// Dark/light mode
		if isDarkModeOn {
			floatingButton.buttonColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
		} else {
			floatingButton.buttonColor = .lightGray
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		navigationItem.titleView = nil
		updateData()
		tableView.reloadData()
		
		// Set up table view
		title = group.name
		tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
		let starred = UserDefaults.standard.string(forKey: "starredGroups")?.contains(group.groupId) ?? false
		starButton.image = UIImage(named: starred ? "star2" : "star")

		if !appearedFirstTime {
			// Set up floating button
			while (floatingButton.items.count != 0) {
				floatingButton.removeItem(index: 0)
			}
			
			longPressFloatyGesture.isEnabled = false
			if AppDelegate.administratorAccess {
				if group.name == "Administration" {
					while (floatingButton.items.count != 0) {
						floatingButton.removeItem(index: 0)
					}
					unlocked = true
					longPressFloatyGesture.isEnabled = true
					addNormalFloatingButtonItems()
				} else {
					while (floatingButton.items.count != 0) {
						floatingButton.removeItem(index: 0)
					}
					addAdminFloatingButtonItems()
				}
				floatyTapGesture.isEnabled = false
				floatingButton.buttonImage = UIImage(named: "triple dots") // triple dots
			} else {
				floatyTapGesture.isEnabled = true
				floatingButton.buttonImage = UIImage(named: "locked") // lock
			}
		}
		
		appearedFirstTime = true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		if updateAtIndex != -1 {
			tableView.scrollToRow(at: IndexPath(row: updateAtIndex, section: 0), at: .top, animated: true)
			updateAtIndex = -1
		}
	}
	
	// MARK: - Table View
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row == 0 {
			let groupHeader = tableView.dequeueReusableCell(withIdentifier: "groupheader", for: indexPath) as! GroupHeaderTableViewCell
			if let image = group.loadedImage {
				groupHeader.imageViewContainer.isHidden = false
				groupHeader.topConstraint.constant = 0
				groupHeader.groupImageView.image = image
			} else {
				groupHeader.imageViewContainer.isHidden = true
				groupHeader.topConstraint.constant = 15
			}
			groupHeader.descriptionLabel.text = group.description
			groupHeader.emailButton.setTitle(group.email, for: .normal)

			let value: CGFloat = isDarkModeOn ? 95.0 : 224.0
			groupHeader.additionalSpaceView.backgroundColor = UIColor(red: value/255, green: value/255, blue: value/255, alpha: 1)
			groupHeader.updateConstraintsIfNeeded()
			
			return groupHeader
		}
		
		return super.tableView(tableView, cellForRowAt: indexPath)
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if updateAtIndex != -1 && indexPath.row == updateAtIndex + 1 {
			// Animate go-to-row with red flash (post saved)
			tableView.isScrollEnabled = false
			let card = cell as! CardTableViewCell
			let color: UIColor
			let post = posts[indexPath.row - 1]
			if post.isPinned { color = UIColor(red: 250.0/255, green: 225.0/255, blue: 0, alpha: 1)
			} else {
				switch post.type {
				case .announcement:
					color = UIColor(red: 19.0/255, green: 110.0/255, blue: 171.0/255, alpha: 1)
				case .event:
					color = UIColor(red: 50.0/255, green: 140.0/255, blue: 193.0/255, alpha: 1)
				case .meeting:
					color = UIColor(red: 50.0/255, green: 176.0/255, blue: 206.0/255, alpha: 1)
				}
			}
			card.cardView.backgroundColor = color
			UIView.animate(withDuration: Double(updateAtIndex) * 0.1 - 0.1, animations: {
				card.alpha = 1
			}) { _ in
				UIView.animate(withDuration: 0.4, delay: 1, animations: {
					card.cardView.backgroundColor = .red
				}) { _ in
					UIView.animate(withDuration: 0.4, animations: {
						card.cardView.backgroundColor = color
					}, completion: { _ in self.tableView.isScrollEnabled = true })
				}
			}
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return indexPath.row == 1 && posts.count == 0 ? 150 : UITableView.automaticDimension
	}
	
	// MARK: - Swipe Actions
	
	override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let config = super.tableView(tableView, leadingSwipeActionsConfigurationForRowAt: indexPath)!
		let post = self.posts[indexPath.row - numHeaderRows]
		var actions = config.actions
		
		if unlocked && SimpleDate.now < post.time {
			let editAction = UIContextualAction(style: .normal, title: "") { (action, sourceView, completionHandler) in
				self.promptAboutProgress(with: post, action: .edit)
				/*
				PostFormTableViewController.postFormVc.actionType = .edit
				PostFormTableViewController.postFormVc.post = post
				PostFormTableViewController.postFormVc.appearedFirstTime = false
				if let postFormNc = PostFormTableViewController.postFormVc.navigationController {
					self.present(postFormNc, animated: true, completion: nil)
				}
				*/
				completionHandler(true)
			}
			editAction.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
			editAction.image = UIImage(named: "edit")?.withRenderingMode(.alwaysOriginal)
			actions.append(editAction)
		}
		
		let swipeAction = UISwipeActionsConfiguration(actions: actions)
		return swipeAction
	}
	
	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let config = super.tableView(tableView, trailingSwipeActionsConfigurationForRowAt: indexPath)
		var actions = config?.actions ?? [UIContextualAction]()
		if unlocked {
			let removeAction = UIContextualAction(style: .normal, title: "") { (action, sourceView,completionHandler) in
				let post = self.posts[indexPath.row - 1]
				let noAction = AlertAction.cancel("No")
				let yesAction = AlertAction.normal(UIAlertAction(title: "Yes", style: .default) { _ in
					let post = self.posts[indexPath.row - 1]
					Post.allPosts.remove( self.posts[indexPath.row - 1])
					self.posts.remove(at: indexPath.row - 1)
					self.tableView.beginUpdates()
					self.tableView.deleteRows(at: [indexPath], with: .left)
					if self.posts.count == 0 {
						self.tableView.insertRows(at: [indexPath], with: .none)
					}
					self.tableView.endUpdates()
					post.toPFObject().deleteEventually()
					print("Will delete post \(post.postId) eventually")
				})
				self.alert(title: "Confirmation", message: "Are you sure you want to delete the \(post.type) \"\(post.titleDisplay)\"?", actions: [noAction, yesAction])
			}
			removeAction.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
			removeAction.image = UIImage(named: "delete")?.withRenderingMode(.alwaysOriginal)
			actions.insert(removeAction, at: 0)
		}
		let swipeAction = UISwipeActionsConfiguration(actions: actions)
		swipeAction.performsFirstActionWithFullSwipe = false
		return swipeAction
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showCardDetail" {
			if let indexPath = tableView.indexPathForSelectedRow {
				let expandedCard = segue.destination as! CardDetailTableViewController
				expandedCard.post = posts[indexPath.row - 1]
			}
		}
	}
	
	func presentPostForm(with post: Post, action: PostFormTableViewController.ActionType) {
		PostFormTableViewController.postFormVc.actionType = action
		PostFormTableViewController.postFormVc.post = post
		PostFormTableViewController.postFormVc.appearedFirstTime = false
		if let postFormNc = PostFormTableViewController.postFormVc.navigationController {
			self.present(postFormNc, animated: true, completion: nil)
		}
	}
	
	func promptAboutProgress(with post: Post, action: PostFormTableViewController.ActionType) {
		if action == .add {
			if let group = UserDefaults.standard.string(forKey: "addPost.group"), let type = Post.PostType(rawValue: 2), post.type != type || self.group.name != String(group.dropLast()) {
				let noAction = AlertAction.cancel("No")
				let yesAction = AlertAction.normal(UIAlertAction(title: "Yes", style: .default, handler: { _ in
					UserDefaults.standard.removeObject(forKey: "addPost.info")
					UserDefaults.standard.removeObject(forKey: "addPost.date")
					UserDefaults.standard.removeObject(forKey: "addPost.image")
					
					UserDefaults.standard.removeObject(forKey: "addPost.group")
					self.presentPostForm(with: post, action: action)
				}))
				alert(title: "Unsaved Information", message: "You have progress from the last time you were creating a \(type) for \(group). Would you like to continue? (This will delete the progress.)", actions: [noAction, yesAction])
			} else {
				presentPostForm(with: post, action: action)
			}
		} else {
			if let thing = UserDefaults.standard.stringArray(forKey: "post.\(post.postId).info") {
				let noAction = AlertAction.normal(UIAlertAction(title: "No", style: .default, handler: { _ in
					UserDefaults.standard.removeObject(forKey: "post.\(post.postId).info")
					UserDefaults.standard.removeObject(forKey: "post.\(post.postId).date")
					UserDefaults.standard.removeObject(forKey: "post.\(post.postId).image")
					
					self.presentPostForm(with: post, action: action)
				}))
				let yesAction = AlertAction.normal(UIAlertAction(title: "Yes", style: .default, handler: { _ in
					self.presentPostForm(with: post, action: action)
				}))
				alert(title: "Unsaved Information", message: "You have progress from the last time you were editing this post. Would you like to load it? (\"No\" will delete the progress.)", actions: [noAction, yesAction])
			} else {
				presentPostForm(with: post, action: action)
			}
		}
	}
	
	// MARK: - Floaty
	
	func addNormalFloatingButtonItems() {
		func checkCooldown() -> Bool {
			var mostRecentTime: SimpleDate = SimpleDate()
			for post in posts {
				if mostRecentTime < post.creationTime {
					mostRecentTime = post.creationTime
				}
			}
			if SimpleDate.now < mostRecentTime.forward(by: 1, .hour) {
				alert(title: "Cooldown", message: "Groups must wait at least an hour between posts. The last post was \(mostRecentTime.description).", actions: [])
				return true
				}
			return false
		}
		
		floatingButton.addItem("Edit group info", icon: UIImage(named: "edit")) { item in
			GroupFormTableViewController.groupFormVc.actionType = .edit
			GroupFormTableViewController.groupFormVc.group = self.group
			GroupFormTableViewController.groupFormVc.appearedFirstTime = false
		
			if let groupFormNc = GroupFormTableViewController.groupFormVc.navigationController {
				self.present(groupFormNc, animated: true, completion: nil)
			}
		}
		floatingButton.addItem("Post a meeting", icon: UIImage(named: "create")) { item in
			if checkCooldown() {
				self.floatingButton.close()
				return
			}
			
			self.promptAboutProgress(with: Post(type: .meeting, group: self.group.name), action: .add)
		}
		floatingButton.addItem("Post an event", icon: UIImage(named: "create")) { item in
			if checkCooldown() {
				self.floatingButton.close()
				return
			}
			
			self.promptAboutProgress(with: Post(type: .event, group: self.group.name), action: .add)
		}
		floatingButton.addItem("Post an announcement", icon: UIImage(named: "create")) { item in
			if checkCooldown() {
				self.floatingButton.close()
				return
			}
			
			self.promptAboutProgress(with: Post(type: .announcement, group: self.group.name), action: .add)
		}
	}
	
	func addAdminFloatingButtonItems() {
		floatingButton.addItem("Reset password", icon: UIImage(named: "warning")) { item in
			self.alert(title: "Are you sure you want to reset the password for \(self.group.name)?", message: "", actions: [
				AlertAction.cancel("No"),
				AlertAction.normal(UIAlertAction(title: "Yes", style: .default) { _ in
					self.group.generatePassword(saveToParse: true)
					self.alert(title: "Password Reset", message: "The new password for \(self.group.name) is \"\(self.group.password)\".", actions: [])
				})
			])
		}
		if posts.count == 0 {
			floatingButton.addItem("Delete group", icon: UIImage(named: "delete")) { item in
				let noAction = AlertAction.cancel("No")
				let yesAction = AlertAction.normal(UIAlertAction(title: "Yes", style: .default) { _ in
					self.group.toPFObject().deleteInBackground { (success, error) in
						if success {
							Group.allGroups.remove(self.group)
							UserDefaults.standard.set(UserDefaults.standard.string(forKey: "starredGroups")!.replacingOccurrences(of: self.group.groupId + ";", with: ""), forKey: "starredGroups")
							self.navigationController!.popViewController(animated: true)
							print("Successfully deleted the group")
						} else {
							print("Error: \(error?.localizedDescription ?? "Unknown error")")
							return
						}
					}
				})
				self.alert(title: "Are you sure you want to delete \(self.group.name)?", message: "This action cannot be undone.", actions: [noAction, yesAction])
			}
		}
	}

	// MARK: - Updates
	
	override func updateData() {
		super.updateData()
		posts = Post.allPosts.filter({ $0.group == group.name }).sorted(by: Comparators.selectedSortMethod)
		
		group = Group.allGroups.first { $0.groupId == group.groupId }!
	}
	
}
