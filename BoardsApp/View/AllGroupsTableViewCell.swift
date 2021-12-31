//
//  AllGroupsTableViewCell.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/5/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit

class AllGroupsTableViewCell: UITableViewCell {
	
	// MARK: - Outlets
	
	@IBOutlet var button: UIButton?
	@IBOutlet var groupNameLabel: UILabel!
	var group: Group!
	
	// MARK: - Actions
	
	@IBAction func buttonClicked(_ sender: UIButton) {
		if let starredGroups = UserDefaults.standard.string(forKey: "starredGroups") {
			if starredGroups.contains(group.groupId) {
				UserDefaults.standard.set(starredGroups.replacingOccurrences(of: group.groupId + ";", with: ""), forKey: "starredGroups")
				sender.setImage(UIImage(named: "star"), for: .normal)
			} else {
				UserDefaults.standard.set(starredGroups + group.groupId + ";", forKey: "starredGroups")
				sender.setImage(UIImage(named: "star2"), for: .normal)
			}
			
			print("starredGroups: \(UserDefaults.standard.string(forKey: "starredGroups") ?? "")\n")
		}
	}

}
