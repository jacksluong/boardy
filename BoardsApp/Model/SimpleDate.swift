//
//  SimpleDate.swift
//  BoardsApp
//
//  Created by Jacky Luong on 6/27/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import Foundation

struct SimpleDate {
	
	static var calendar = Calendar.current
	
	var calendarTime: (month: Int, day: Int, year: Int)
	var clockTime: (hour: Int, minute: Int)
	var description: String {
		var base = "\(calendarTime.month)/\(calendarTime.day)/\(calendarTime.year)"
		let m = clockTime.hour >= 12 ? "PM" : "AM"
		let hour = clockTime.hour % 12 != 0 ? clockTime.hour % 12 : 12
		base += " \(hour):" + (clockTime.minute < 10 ? "0" : "") + "\(clockTime.minute) \(m)"
		return base
	}
	var dateForm: Date {
		var dateComponents = DateComponents()
		dateComponents.day = calendarTime.day
		dateComponents.month = calendarTime.month
		dateComponents.year = calendarTime.year
		dateComponents.hour = clockTime.hour
		dateComponents.minute = clockTime.minute
		return Calendar.current.date(from: dateComponents)!
	}
	var arrayForm: [Int] {
		return [calendarTime.month, calendarTime.day, calendarTime.year, clockTime.hour, clockTime.minute]
	}
	static var now: SimpleDate {
		return SimpleDate(from: Date(timeIntervalSinceNow: 0))
	}
	
	init() {
		calendarTime = (0,0,0)
		clockTime = (0,0)
	}
	
	init(calendarTime: (Int, Int, Int), clockTime: (Int, Int)) {
		self.calendarTime = calendarTime
		self.clockTime = clockTime
	}
	
	init(from date: Date) {
		calendarTime.month = Calendar.current.component(.month, from: date)
		calendarTime.day = Calendar.current.component(.day, from: date)
		calendarTime.year = Calendar.current.component(.year, from: date)
		clockTime.hour = Calendar.current.component(.hour, from: date)
		clockTime.minute = Calendar.current.component(.minute, from: date)
	}
	
	init(from array: [Int]) {
		calendarTime = (array[0], array[1], array[2])
		clockTime = (array[3], array[4])
	}
	
	static func ==(left: SimpleDate, right: SimpleDate) -> Bool {
		return left.calendarTime == right.calendarTime && left.clockTime == right.clockTime
	}
	
	static func <(left: SimpleDate, right: SimpleDate) -> Bool {
		if left.calendarTime.year != right.calendarTime.year {
			return left.calendarTime.year < right.calendarTime.year
		} else if left.calendarTime.month != right.calendarTime.month {
			return left.calendarTime.month < right.calendarTime.month
		} else if left.calendarTime.day != right.calendarTime.day {
			return left.calendarTime.day < right.calendarTime.day
		} else if left.clockTime.hour != right.clockTime.hour {
			return left.clockTime.hour < right.clockTime.hour
		} else {
			return left.clockTime.minute < right.clockTime.minute
		}
	}
	
	func forward(by quantity: Int, _ unit: TimeUnit) -> SimpleDate {
		if unit == .month {
			return SimpleDate(calendarTime: ((calendarTime.month + quantity - 1) % 12 + 1, calendarTime.day, calendarTime.year + (calendarTime.month + quantity - 1) / 12), clockTime: clockTime)
		}
		return SimpleDate(from: Date(timeInterval: TimeInterval(quantity * unit.rawValue), since: dateForm))
	}
	
	enum TimeUnit: Int {
		case minute = 60
		case hour = 3600
		case day = 86400
		case month = 0
	}
	
}
