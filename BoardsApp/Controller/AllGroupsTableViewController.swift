//
//  AllGroupsTableViewController.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/5/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit
import Parse

class AllGroupsTableViewController: UITableViewController {
	
	// MARK: - Properties
	
	static var allGroups: [Group] = []
	static var starredGroups: [Group] {
		if let starredGroups = UserDefaults.standard.string(forKey: "starredGroups") {
			return allGroups.filter({ starredGroups.contains($0.groupId) })
		} else {
			return []
		}
	}
	
	// MARK: - Initialization
	
    override func viewDidLoad() {
        super.viewDidLoad()
		colorBarButtonItems()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		Group.allGroups.sort {
			if $0.name == "Administration" {
				return true
			} else if $1.name == "Administration" {
				return false
			} else {
				return $0.name < $1.name
			}
		}
		tableView.reloadData()
	}

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return Group.allGroups.count - (AppDelegate.administratorAccess ? -1 : 1)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row == Group.allGroups.count {
			return tableView.dequeueReusableCell(withIdentifier: "addgroupcell", for: indexPath) as! AllGroupsTableViewCell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "groupcell", for: indexPath) as! AllGroupsTableViewCell
			let group = Group.allGroups[indexPath.row + (AppDelegate.administratorAccess ? 0 : 1)]
			cell.groupNameLabel.text = group.name
			let starred = UserDefaults.standard.string(forKey: "starredGroups")?.contains(group.groupId) ?? false
			cell.button?.setImage(UIImage(named: starred ? "star2" : "star"), for: .normal)
			cell.group = group

			return cell
		}
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		if indexPath.row == Group.allGroups.count {
			GroupFormTableViewController.groupFormVc.actionType = .add
			GroupFormTableViewController.groupFormVc.group = Group()
			GroupFormTableViewController.groupFormVc.appearedFirstTime = false
			self.present(GroupFormTableViewController.groupFormVc.navigationController!, animated: true, completion: nil)
		}
	}
	
    // MARK: - Navigation

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showGroupPage" {
			if let indexPath = tableView.indexPathForSelectedRow {
				let groupPage = segue.destination as! GroupPageViewController
				groupPage.group = Group.allGroups[indexPath.row + (AppDelegate.administratorAccess ? 0 : 1)]
				groupPage.unlocked = false
				groupPage.appearedFirstTime = false
				groupPage.updateData()
			}
		}
    }

}
