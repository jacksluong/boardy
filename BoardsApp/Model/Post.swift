//
//  Post.swift
//  BoardsApp
//
//  Created by Jacky Luong on 6/26/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import Foundation
import Parse
import UserNotifications

class Post: Equatable {
	
	// MARK: - Properties
	
	static var allPosts: [Post] = []
	static var hiddenPosts: [Post] = []
	
	static func == (lhs: Post, rhs: Post) -> Bool {
		return lhs.postId == rhs.postId || (lhs.group == rhs.group && lhs.time.calendarTime == rhs.time.calendarTime && lhs.time.clockTime == rhs.time.clockTime && lhs.title == rhs.title && lhs.type == rhs.type)
	}

	var postId: String
	private(set) var type: PostType
	var title: String
	var displayTitle: String {
		return title.isEmpty ? "\(type)".capitalized : title
	}
	var description: String
	var time: SimpleDate
	var group: String
	var location: String
	var image: PFFileObject?
	var loadedImage: UIImage?
	var creationTime: SimpleDate
	var hidden: Bool
	var isPinned: Bool {
		return UserDefaults.standard.string(forKey: "pinnedPosts")!.contains(postId)
	}
	var timeDisplay: String {
		var base = "\(time.calendarTime.month)/\(time.calendarTime.day)/\(time.calendarTime.year % 100)"
		switch type {
		case .announcement:
			return "Expires on \(time.calendarTime.month)/\(time.calendarTime.day)"
		case .event:
			if time.clockTime == (0, 0) {
				return base
			}
			fallthrough
		case .meeting:
			let m = time.clockTime.hour >= 12 ? "PM" : "AM"
			let hour = time.clockTime.hour % 12 != 0 ? time.clockTime.hour % 12 : 12
			base += " \(hour):" + (time.clockTime.minute < 10 ? "0" : "") + "\(time.clockTime.minute) \(m)"
		}
		return base
	}
	var titleDisplay: String {
		return title.isEmpty ? "\(type)".capitalized : title
	}
	
	// MARK: - Initialization
	
	init(type: PostType, title: String = "", description: String = "", time: SimpleDate = SimpleDate(calendarTime: (0,0,0), clockTime: (0,0)), group: String = "", location: String = "", imageData: Data? = nil) {
		self.type = type
		self.title = title
		self.description = description
		self.time = time
		self.group = group
		self.location = location
		if let imageData = imageData {
			image = PFFileObject(data: imageData)
		}
		
		creationTime = SimpleDate.now
		hidden = false
		
		postId = ""
	}
	
	init(pfObject: PFObject) {
		type = PostType(rawValue: pfObject["type"] as! Int)!
		title = pfObject["title"] as! String
		description = pfObject["description"] as! String
		time = SimpleDate(from: pfObject["time"] as! Date)
		group = pfObject["group"] as! String
		if let location = pfObject["location"] as? String {
			self.location = location
		} else {
			location = ""
		}
		image = pfObject["image"] as? PFFileObject
		hidden = pfObject["hidden"] as! Bool
		
		creationTime = SimpleDate(from: pfObject.createdAt!)
		
		postId = pfObject.objectId!
	}
	
	// MARK: - Parse
	
	func toNewPFObject() -> PFObject {
		let postObject = PFObject(className: "Post")
		postObject["title"] = title
		postObject["type"] = type.rawValue
		postObject["description"] = description
		postObject["time"] = time.dateForm
		postObject["group"] = group
		postObject["location"] = location
		postObject["hidden"] = hidden
		if let image = image {
			postObject["image"] = image
		}
		
		return postObject
	}
	
	func toPFObject() -> PFObject {
		let postObject = toNewPFObject()
		postObject.objectId = postId
		return postObject
	}
	
	// MARK: - Notifications
	
	func updateNotifications() {
		if type != .announcement {
			if isPinned {
				scheduleNotifications()
			} else {
				unscheduleNotifications()
			}
		}
	}
	
	func scheduleNotifications() {
		if time < SimpleDate.now {
			// Schedule notification for when the post time is now
			let content = UNMutableNotificationContent()
			content.title = "\(group): \(displayTitle)"
			content.body = "The \(type) is now!"
			content.sound = UNNotificationSound.default
			content.badge = 1
			
			let date = SimpleDate.calendar.dateComponents([.month, .day, .year, .hour, .minute], from: time.dateForm)
			let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
			let request = UNNotificationRequest(identifier: "happen.\(postId)", content: content, trigger: trigger)
			
			UNUserNotificationCenter.current().add(request) { (error) in
				if let error = error {
					print("Error \(error.localizedDescription)")
				}
			}
			
			if time.forward(by: 1, .day) < SimpleDate.now {
				// Schedule notification for a reminder a day in advance
				let content = UNMutableNotificationContent()
				content.title = "\(group): \(displayTitle)"
				var body = "The \(type) is tomorrow"
				if time.clockTime != (0, 0) {
					body += " at \(time.clockTime.hour):\(time.clockTime.minute < 10 ? "0" : "")\(time.clockTime.minute)."
				}
				content.body = body
				content.sound = UNNotificationSound.default
				content.badge = 1
				
				let date = SimpleDate.calendar.dateComponents([.month, .day, .year, .hour, .minute], from: time.forward(by: 1, .day).dateForm)
				let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
				let request = UNNotificationRequest(identifier: "remind.\(postId)", content: content, trigger: trigger)
				
				UNUserNotificationCenter.current().add(request) { (error) in
					if let error = error {
						print("Error \(error.localizedDescription)")
					}
				}
			}
		}
	}
	
	func unscheduleNotifications() {
		UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["happen.\(postId)"])
		UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["remind.\(postId)"])
	}
	
	enum PostType: Int {
		case announcement = 1
		case event
		case meeting
	}
	
	// MARK: - Miscellaneous
	
	func copy() -> Post {
		let post = Post(type: type, title: title, description: description, time: time, group: group, location: location)
		post.creationTime = creationTime
		post.image = image
		post.loadedImage = loadedImage
		post.hidden = hidden
		post.postId = postId
		return post
	}
	
	func editingWasInProgress() -> Bool {
		return UserDefaults.standard.stringArray(forKey: "post.\(postId).info") != nil
	}
	
}
