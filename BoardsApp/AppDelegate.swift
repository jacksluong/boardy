//
//  AppDelegate.swift
//  BoardsApp
//
//  Created by Jacky Luong on 6/23/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit
import Parse
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	static var administratorAccess: Bool {
		let lastActivated = SimpleDate(from: (UserDefaults.standard.array(forKey: "lastAdminActivation") as! [Int]))
		return SimpleDate.now < lastActivated.forward(by: 20, .minute)
	}
	static var mainNavigationController: UINavigationController!
	
	var window: UIWindow?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

		// Initialize Parse
		let configuration = ParseClientConfiguration {
			$0.applicationId = "7hnrdHa6YjKeYXL3Ij1PnlPjgu3RkO6Si0dfIKIP"
			$0.clientKey = "Jmhj2YH3kaVgQjXaOqgR8Zc4AkMtaYcvbe5FOcmp"
			$0.server = "https://parseapi.back4app.com"
		}
		Parse.initialize(with: configuration)
		
		// Initialize UserDefaults
		if UserDefaults.standard.string(forKey: "pinnedPosts") == nil {
			UserDefaults.standard.set("", forKey: "pinnedPosts")
		}
		if UserDefaults.standard.string(forKey: "starredGroups") == nil {
			UserDefaults.standard.set("", forKey: "starredGroups")
		}
		if UserDefaults.standard.array(forKey: "notifications") == nil {
			UserDefaults.standard.set([false], forKey: "notifications")
		}
		if UserDefaults.standard.array(forKey: "lastAdminActivation") == nil {
			UserDefaults.standard.set(SimpleDate().arrayForm, forKey: "lastAdminActivation")
		}
		if UserDefaults.standard.array(forKey: "lastAdminAttempt") == nil {
			UserDefaults.standard.set(SimpleDate().arrayForm, forKey: "lastAdminAttempt")
		}
		
		// Request for notifications
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
			if granted {
				print("User notifications are allowed.")
			} else {
				print("User notifications are not allowed.")
			}
		}
		
		// Initialize back indicator
		let backButtonImage = UIImage(named: "back")
		UINavigationBar.appearance().backIndicatorImage = backButtonImage
		UINavigationBar.appearance().backIndicatorTransitionMaskImage = backButtonImage
		
		// Currernt status
		print("\npinnedPosts: \(UserDefaults.standard.string(forKey: "pinnedPosts") ?? "")")
		print("starredGroups: \(UserDefaults.standard.string(forKey: "starredGroups") ?? "")\n")
		if AppDelegate.administratorAccess {
			let lastActivated = SimpleDate(from: (UserDefaults.standard.array(forKey: "lastAdminActivation") as! [Int]))
			print("Admin access expire(s/d) at " + lastActivated.forward(by: 20, .minute).description)
		}
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		// Saves changes in the application's managed object context before the application terminates.
	}
	
	static func loadDataFromParse(withCachePolicy cachePolicy: PFCachePolicy, caller: UIViewController) {
		if let vc = caller as? StartingViewController {
			vc.taskLabel.text = "Loading posts"
		}
		
		let query = PFQuery(className: "Post")
		query.cachePolicy = cachePolicy
		query.findObjectsInBackground() { (objects, error) in
			// Add all posts found to the allPosts array
			if let objects = objects {
				Post.allPosts = []
				for object in objects {
 					let post = Post(pfObject: object)
					if let imageData = post.image, let postImageData = try? imageData.getData() {
						if let image = UIImage(data: postImageData) {
							post.loadedImage = image
						}
					}
					Post.allPosts.append(post)
				}
				Post.allPosts.sort(by: Comparators.selectedSortMethod)
				
				// Delete expired posts
				for post in Post.allPosts {
					if post.time.forward(by: post.type == .announcement ? 0 : 2, .day) < SimpleDate.now {
						post.toPFObject().deleteInBackground { (success, error) in
							if success {
								if post.isPinned {
									post.unscheduleNotifications()
								}
								print("Deleted expired post \(post.postId)")
								
								// Remove saved form progress if exists
								if let _ = UserDefaults.standard.stringArray(forKey: "post.\(post.postId).info") {
									UserDefaults.standard.removeObject(forKey: "post.\(post.postId).info")
									UserDefaults.standard.removeObject(forKey: "post.\(post.postId).date")
										UserDefaults.standard.removeObject(forKey: "post.\(post.postId).image")
								}
								
								Post.allPosts.remove(post)
							} else {
								print("Failed to delete expired post \(post.postId) because \(error?.localizedDescription ?? "unknown error"). Will delete eventually.")
								post.toPFObject().deleteEventually()
							}
						}
					}
				}
				
				if let vc = (caller as? HomeViewController) ?? caller as? GroupPageViewController {
					let oldPosts = vc.posts
					vc.updateData()
					let newPosts = vc.posts
					vc.updateTableView(oldPosts: oldPosts, newPosts: newPosts)
				}
			}
			
			// Remove any pinned posts that no longer exist
			if let ppText = UserDefaults.standard.string(forKey: "pinnedPosts"), !ppText.isEmpty {
				let pinnedPosts = ppText.components(separatedBy: ";").dropLast()
				for postId in pinnedPosts {
					if !Post.allPosts.contains(where: { $0.postId == postId }) {
						UserDefaults.standard.set(ppText.replacingOccurrences(of: postId + ";", with: ""), forKey: "pinnedPosts")
					}
				}
			}
			
			// Move hidden posts to separate collection
			Post.hiddenPosts = []
			for index in 0..<Post.allPosts.count {
				if Post.allPosts[index - Post.hiddenPosts.count].hidden {
					Post.hiddenPosts.append(Post.allPosts.remove(at: index))
				}
			}
			
			
			// End of posts query. Begin groups query.
			
			
			if let vc = caller as? StartingViewController {
				vc.taskLabel.text = "Loading groups"
			}
			
			let query2 = PFQuery(className: "Group")
			query2.cachePolicy = cachePolicy
			query2.findObjectsInBackground() { (objects, error) in
				if let objects = objects {
					// Add all groups to the allGroups array
					Group.allGroups = []
					for object in objects {
						let group = Group(pfObject: object)
						if let imageData = group.image, let groupImageData = try? imageData.getData() {
							if let image = UIImage(data: groupImageData) {
								group.loadedImage = image
							}
						}
						Group.allGroups.append(group)
					}
					Group.allGroups.sort {
						if $0.name == "Administration" {
							return true
						} else if $1.name == "Administration" {
							return false
						} else {
							return $0.name < $1.name
						}
					}
					
					// Remove any starred groups that no longer exist
					if let sgText = UserDefaults.standard.string(forKey: "starredGroups"), !sgText.isEmpty {
						let starredGroups = sgText.components(separatedBy: ";").dropLast()
						for groupId in starredGroups {
							if !Group.allGroups.contains(where: { $0.groupId == groupId }) {
								UserDefaults.standard.set(sgText.replacingOccurrences(of: groupId + ";", with: ""), forKey: "starredGroups")
							}
						}
					}
				}
				
				
				// End of groups query.
				
				
				if let vc = caller as? StartingViewController, let navigationController = vc.navigationController {
					mainNavigationController = navigationController
					vc.performSegue(withIdentifier: "start", sender: nil)
					navigationController.setNavigationBarHidden(false, animated: false)
				}
			}
		}
		
	}
}

