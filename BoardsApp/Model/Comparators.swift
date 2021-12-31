//
//  Comparators.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/16/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import Foundation

class Comparators {
	static var selectedSortMethod: (Post, Post) -> Bool {
		return UserDefaults.standard.bool(forKey: "sortByTimePosted") ? Comparators.recentFirst(post1:post2:) : Comparators.soonestFirst(post1:post2:)
	}
	
	private static func soonestFirst(post1: Post, post2: Post) -> Bool {
		return checkIfPinnedOrPast(post1, post2) ?? (post1.time < post2.time)
	}
	
	private static func recentFirst(post1: Post, post2: Post) -> Bool {
		return checkIfPinnedOrPast(post1, post2) ?? (post2.creationTime < post1.creationTime)
	}
	
	private static func checkIfPinnedOrPast(_ post1: Post, _ post2: Post) -> Bool? {
		if post1.isPinned && !post2.isPinned {
			return true
		} else if !post1.isPinned && post2.isPinned {
			return false
		}
		if post1.time < SimpleDate.now && SimpleDate.now < post2.time {
			return false
		} else if post2.time < SimpleDate.now && SimpleDate.now < post1.time {
			return true
		}

		return nil
	}
}
