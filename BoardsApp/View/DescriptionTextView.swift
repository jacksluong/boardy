//
//  DescriptionTextView.swift
//  BoardsApp
//
//  Created by Jacky Luong on 8/7/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit

class DescriptionTextView: UITextView {
	
	var placeholder = ""
	var placeholderOn = true
	var displayText: String {
		return placeholderOn ? "" : text
	}

	override func awakeFromNib() {
		backgroundColor = UIColor(red: 230.0/255, green: 230.0/255, blue: 230.0/255, alpha: 1)
		contentInset = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
		textColor = .lightGray
		text = placeholder
		
		// Done button
		let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.inputAccessoryView = doneToolbar
	}
	
	@objc func doneButtonAction()
    {
        self.resignFirstResponder()
    }
	
	func togglePlaceholder() {
		if placeholderOn {
			textColor = .black
			text = ""
			placeholderOn = false
		} else {
			textColor = .lightGray
			text = placeholder
			placeholderOn = true
		}
	}
	
}
