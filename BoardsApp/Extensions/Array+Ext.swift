//
//  Array+Ext.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/29/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import Foundation

extension Array {
	/// Adds a new element into a sorted array to maintain a sorted order.
	mutating func append(_ newElement: Element, sortedBy areInIncreasingOrder: (Element, Element) -> Bool) {
		if count == 0 {
			append(newElement)
			return
		}
		for index in 0..<count {
			if !areInIncreasingOrder(self[index], newElement) {
				insert(newElement, at: index)
				break
			} else if index == count - 1 {
				append(newElement)
			}
		}
	}
}

extension Array where Element: Equatable {
	/// Removes the first occurrence of the given element if found.
	mutating func remove(_ element: Element) {
		for index in 0..<count {
			if self[index] == element {
				remove(at: index)
				return
			}
		}
	}
}

extension Array where Element == Post {
	/// A string representation of the array using the ids of the posts
	var stringForm: String {
		var string = "["
		for post in self {
			string += post.postId + ", "
		}
		return String(string.dropLast(2)) + "]"
	}
}
