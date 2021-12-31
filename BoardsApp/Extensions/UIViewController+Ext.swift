//
//  UIAlertController+Ext.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/9/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
	
	var isDarkModeOn: Bool {
		if #available(iOS 12.0, *) {
			return traitCollection.userInterfaceStyle == .dark
		}
		return false
	}
	
	// MARK: - Alerts
	
	enum AlertAction {
		case cancel(_ title: String)
		case normal(_ action: UIAlertAction)
		case withTextField(title: String, style: UIAlertAction.Style, checkFor: String, matchHandler: (() -> Void)? = nil, noMatchHandler: (() -> Void)? = nil)
	}
	
	/// Trigger an alert with the given title, message, and actions (if any).
	func alert(title: String?, message: String, actions: [AlertAction], textFieldPlaceholder: String? = nil) {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

		if actions.count == 0 {
			alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
		} else {
			for alertAction in actions {
				var actualAction: UIAlertAction
				switch alertAction {
				case .cancel(let title):
					actualAction = UIAlertAction(title: title, style: .cancel)
				case .normal(let action):
					actualAction = action
				case .withTextField(let title, let style, let checkFor, let matchHandler, let noMatchHandler):
					actualAction = UIAlertAction(title: title, style: style, handler: { action in
						if let password = alertController.textFields?.first?.text, password == checkFor {
							matchHandler?()
						} else {
							noMatchHandler?()
						}
					})
				}
				
				alertController.addAction(actualAction)
			}
		}
		
		if let placeholder = textFieldPlaceholder {
			alertController.addTextField {
				textField in
				textField.placeholder = placeholder
				textField.isSecureTextEntry = placeholder == "Password"
				if #available(iOS 12, *) {
					// iOS 12: Not the best solution, but it works.
					textField.textContentType = .oneTimeCode
					   } else {
					// iOS 11: Disables the autofill accessory view.
					textField.textContentType = .init(rawValue: "")
				}
			}
		}
		
		present(alertController, animated: true, completion: nil)
	}
	
	// MARK: - Visuals
	
	/// Display a brief message in the main navigation bar, regardless of which view controller is on top.
	func displayInNavigationBar(message: String, color: UIColor) {
		if let topViewController = AppDelegate.mainNavigationController.topViewController {
			let label = UILabel()
			label.text = message
			label.textColor = color
			topViewController.navigationItem.titleView = label
			label.alpha = 0
			UIView.animate(withDuration: 0.4, delay: 0.3, animations: {
				label.transform = .identity
				label.alpha = 1
			}) { _ in
				UIView.animate(withDuration: 0.4, delay: 3, options: [], animations: {
					label.alpha = 0
				}) { _ in
					topViewController.navigationItem.titleView = nil
				}
			}
		}
	}
	
	/// Changes the colors of the bar button items as necessary.
	func colorBarButtonItems() {
		let color: UIColor = isDarkModeOn ? .white : .black
		if let leftButton = navigationItem.leftBarButtonItem {
			leftButton.tintColor = color
		}
		if let rightButton = navigationItem.rightBarButtonItem {
			rightButton.tintColor = color
		}
		navigationController?.navigationBar.tintColor = color
	}
}
