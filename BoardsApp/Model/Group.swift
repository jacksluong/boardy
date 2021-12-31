//
//  Group.swift
//  BoardsApp
//
//  Created by Jacky Luong on 6/26/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import Foundation
import Parse

class Group: Equatable {
	
	// MARK: - Properties
	
	static var allGroups: [Group] = []
	
	static func == (lhs: Group, rhs: Group) -> Bool {
		return lhs.name == rhs.name && lhs.description == rhs.description && lhs.email == rhs.email
	}
	
	var groupId: String
	var name: String
	var description: String
	var email: String
	var password: String
	var image: PFFileObject?
	var loadedImage: UIImage?
	
	// MARK: - Initialization
	
	init(name: String = "", description: String = "", email: String = "", imageData: Data? = nil) {
		self.name = name
		self.description = description
		self.email = email
		password = ""
		if let imageData = imageData {
			image = PFFileObject(data: imageData)
		}
		
		groupId = ""
		
		generatePassword(saveToParse: false)
	}
	
	init(pfObject: PFObject) {
		name = pfObject["name"] as! String
		description = pfObject["description"] as! String
		email = pfObject["email"] as! String
		password = pfObject["password"] as! String
		image = pfObject["image"] as? PFFileObject
		
		groupId = pfObject.objectId!
	}
	
	// MARK: - Parse
	
	func toNewPFObject() -> PFObject {
		let groupObject = PFObject(className: "Group")
		groupObject["name"] = name
		groupObject["description"] = description
		groupObject["email"] = email
		if let image = image {
			groupObject["image"] = image
		}
		groupObject["password"] = password
		
		return groupObject
	}
	
	func toPFObject() -> PFObject {
		let groupObject = toNewPFObject()
		groupObject.objectId = groupId
		return groupObject
	}
	
	// MARK: - Miscellaneous
	
	func generatePassword(saveToParse: Bool) {
		let length = Int.random(in: 8...10)
		let pswdChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
		let rndPswd = String((0..<length).compactMap{ _ in pswdChars.randomElement() })
		password = rndPswd
		if saveToParse {
			let updatedGroup = toPFObject()
			updatedGroup.saveInBackground { (success, error) in
				if success {
					print("Successfully updated the group password")
				} else {
					print("Password update error: \(error?.localizedDescription ?? "Unknown error")")
					updatedGroup.saveEventually()
					return
				}
			}
		}
	}
	
	func copy() -> Group {
		let group = Group(name: name, description: description, email: email)
		group.image = image
		group.password = password
		group.groupId = groupId
		group.loadedImage = loadedImage
		return group
	}
	
	func editingWasInProgress() -> Bool {
		return UserDefaults.standard.stringArray(forKey: "group.\(groupId).info") != nil
	}
}
