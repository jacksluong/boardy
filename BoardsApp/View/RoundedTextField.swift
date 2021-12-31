//
//  RoundedTextField.swift
//  BoardsApp
//
//  Created by Jacky Luong on 2/24/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit

class RoundedTextField: UITextField {
	
	var padding = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
	
	override func awakeFromNib() {
		backgroundColor = UIColor(red: 230.0/255, green: 230.0/255, blue: 230.0/255, alpha: 1)
		
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
	
	override func textRect(forBounds bounds: CGRect) -> CGRect {
		return bounds.inset(by: padding)
	}
	
	override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
		return bounds.inset(by: padding)
	}
	
	override func editingRect(forBounds bounds: CGRect) -> CGRect {
		return bounds.inset(by: padding)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.layer.cornerRadius = 5.0
		self.layer.masksToBounds = true
	}
	
}
