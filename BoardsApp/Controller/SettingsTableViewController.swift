//
//  SettingsTableViewController.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/19/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController, UIGestureRecognizerDelegate {
	
	// MARK: - Outlets
	
	@IBOutlet var tOfPostCheck: UIImageView!
	@IBOutlet var tPostedCheck: UIImageView!
	@IBOutlet var postNotifSwitch: UISwitch!
	@IBOutlet var infoLabel: UILabel!
	
	// MARK: - Actions
	
	@IBAction func switchToggled(_ sender: UISwitch) {
		if sender.accessibilityIdentifier == "postSwitch" {
			UserDefaults.standard.set([sender.isOn], forKey: "notifications")
		}
	}
	
	@IBAction func promptForAdmin(_ gestureRecognizer: UIGestureRecognizer) {
		guard infoLabel.backgroundColor != .yellow && gestureRecognizer.state == .began else {
			return
		}
		
		guard SimpleDate(from: UserDefaults.standard.array(forKey: "lastAdminAttempt") as! [Int]).forward(by: 15, .minute) < SimpleDate.now else {
			alert(title: "Cooldown", message: "You must wait at least 15 minutes between each attempt.", actions: [])
			return
		}
		let cancelAction = AlertAction.cancel("Cancel")
		let okAction = AlertAction.withTextField(title: "OK", style: .default, checkFor: Group.allGroups[0].password, matchHandler: {
			UserDefaults.standard.set(SimpleDate.now.arrayForm, forKey: "lastAdminActivation")
			self.infoLabel.backgroundColor = .yellow
			print("Admin access expires at " + SimpleDate.now.forward(by: 20, .minute).description)
			self.alert(title: "Access Activated", message: "Expires \(SimpleDate.now.forward(by: 20, .minute).description)", actions: [])
		})
		
		alert(title: "Administrator Access", message: "", actions: [cancelAction, okAction], textFieldPlaceholder: "Password")
	}
	
	@IBAction func confirmButtonTapped(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}
	
	// MARK: - Initialization
	
    override func viewDidLoad() {
        super.viewDidLoad()
		colorBarButtonItems()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		infoLabel.text = "Click on any row to see a brief description of what it means."
		
		tOfPostCheck.isHidden =
			UserDefaults.standard.bool(forKey: "sortByTimePosted")
		tPostedCheck.isHidden =
			!UserDefaults.standard.bool(forKey: "sortByTimePosted")
		postNotifSwitch.isOn =
			(UserDefaults.standard.array(forKey: "notifications") as! [Bool])[0]

		infoLabel.backgroundColor = AppDelegate.administratorAccess ? .yellow : .clear
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		if #available(iOS 13.0, *), let vc = (presentingViewController as? UINavigationController)?.topViewController as? HomeViewController {
			vc.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
			vc.refresh(self)
		}
	}

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 2
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if indexPath.section == 0 {
			if indexPath.row == 0 {
				UserDefaults.standard.set(false, forKey: "sortByTimePosted")
				tOfPostCheck.isHidden = false
				tPostedCheck.isHidden = true
				infoLabel.text = "Posts with the closest times to now will appear on top of those that have later times."
			} else {
				UserDefaults.standard.set(true, forKey: "sortByTimePosted")
				tOfPostCheck.isHidden = true
				tPostedCheck.isHidden = false
				infoLabel.text = "Posts will appear in order of when they were posted. (Past posts are at the bottom.)"
			}
		} else {
			if indexPath.row == 0 {
				infoLabel.text = "Notifications for pinned posts—reminders when they happen and a day in advance. (Updated every time the app is opened.)"
			}
		}
	}

}
