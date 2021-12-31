//
//  GroupFormTableViewController.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/10/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit
import Parse

class GroupFormTableViewController: UITableViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {
	
	// MARK: - Outlets
	
	@IBOutlet var checkButton: UIBarButtonItem!
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var imageRowLabel: UILabel! {
		didSet {
			imageRowLabel.bounds.inset(by: UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0))
			
		}
	}
	@IBOutlet var nameTextField: RoundedTextField! {
		didSet {
			nameTextField.delegate = self
			nameTextField.autocapitalizationType = .words
		}
	}
	@IBOutlet var emailTextField: RoundedTextField! {
		didSet {
			emailTextField.delegate = self
		}
	}
	@IBOutlet var descriptionTextView: DescriptionTextView! {
		didSet {
			descriptionTextView.delegate = self
		}
	}
	
	// MARK: - Properties
	
	static var groupFormVc: GroupFormTableViewController {
		return (myNavigationController.viewControllers.first as! GroupFormTableViewController)
	}
	static var myNavigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "leadToGroupForm") as! UINavigationController // a reference to keep the navigation controller from deinitializing
	
	var groupPageVc: GroupPageViewController!
	var actionType: ActionType!
	var group: Group!
	var appearedFirstTime = false
	private var imageSelected = false
	private var imageChanged = false
	
	// MARK: - Actions
	
	@IBAction func cancelButtonClicked(_ sender: Any) {
		let noAction = AlertAction.cancel("No")
		let yesAction = AlertAction.normal(UIAlertAction(title: "Yes", style: .default) { _ in
			self.deleteProgress()
			self.dismiss(animated: true, completion: nil)
		})
		alert(title: actionType == .edit ? "Discard Changes?" : "Discard Group?", message: actionType == .edit ? "All unsaved changes will be lost." : "All provided information will not be saved.", actions: [noAction, yesAction])
	}
	
	func saveProgress() {
		// Save all provided information in case saving to the server fails
		// Available for implementation, but decided it's not necessary
		let base = actionType == .add ? "addGroup" : "group.\(group.groupId)"
		UserDefaults.standard.set([nameTextField.text ?? "", emailTextField.text ?? "", descriptionTextView.displayText], forKey: "\(base).info")
		if imageSelected, let imageData = imageView.image?.pngData() {
			UserDefaults.standard.set(imageData, forKey: "\(base).image")
		}
	}
	
	func deleteProgress() {
		let base = actionType == .add ? "addGroup" : "group.\(group.groupId)"
		UserDefaults.standard.removeObject(forKey: "\(base).info")
		UserDefaults.standard.removeObject(forKey: "\(base).image")
	}
	
	@IBAction func submitButtonClicked(_ sender: Any) {
		if actionType == .edit && group.name == nameTextField.text && group.email == emailTextField.text && group.description == descriptionTextView.text && !imageChanged {
			// No info changed
			dismiss(animated: true, completion: nil)
			return
		}
		
		guard let nameText = nameTextField.text, let emailText = emailTextField.text, !nameText.isEmpty && !emailText.isEmpty && !descriptionTextView.placeholderOn else {
			alert(title: "Missing Information", message: "Please provide text in all fields.", actions: [])
			return
		}
		guard Group.allGroups.filter({ $0.name == nameTextField.text! }).count < (actionType == .add ? 1 : 2) else {
			alert(title: "Name Unavailable", message: "That name is already used by another group.", actions: [])
			return
		}
		do {
			if let emailText = emailTextField.text, try NSRegularExpression(pattern: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$", options: .caseInsensitive).firstMatch(in: emailText, options: [], range: NSRange(location: 0, length: emailText.count)) == nil {
				alert(title: "Invalid Email", message: "Please provide a valid email.", actions: [])
				return
			}
		} catch {
			alert(title: "Invalid Email", message: "Please provide a valid email.", actions: [])
			return
		}
		if let name = nameTextField.text, name.count < 4 {
			alert(title: "Invalid Name", message: "The group name must have a minimum of 4 characters.", actions: [])
			return
		}
		if descriptionTextView.text.count < 12 {
			alert(title: "Invalid Description", message: "Please provide a more detailed description about this group for viewers.", actions: [])
			return
		}
		
		// Indicate activity
		let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
		let barButton = UIBarButtonItem(customView: activityIndicator)
		navigationItem.setRightBarButton(barButton, animated: true)
		activityIndicator.startAnimating()
		navigationItem.rightBarButtonItem?.isEnabled = false
		navigationItem.leftBarButtonItem?.isEnabled = false
		view.isUserInteractionEnabled = false
		self.title = "Saving..."
		
		let oldName = group.name
		let oldGroup = group.copy()
		
		func saveGroup() {
			// Save the group itself
			if actionType == .add {
				group.generatePassword(saveToParse: false)
				let newGroup = group.toNewPFObject()
				newGroup.saveInBackground { (success, error) in
					let vc = self.presentingViewController!
					if success {
						print("Successfully added the group")
						// Replace occurrences of the placeholder id
						self.group.groupId = newGroup.objectId!
						Group.allGroups.append(self.group)
						if #available(iOS 13.0, *) {
							vc.viewWillAppear(true)
						}
					} else {
						print("Save error: \(error?.localizedDescription ?? "unknown error")")
						
						self.displayInNavigationBar(message: "Save failed.", color: UIColor(red: 0.8, green: 0, blue: 0, alpha: 1))
					}
					if #available(iOS 13.0, *) {
						self.groupPageVc.viewWillAppear(true)
					}
					self.dismiss(animated: true, completion: nil)
					if success {
						func promptPassword(tried: Bool) {
							let okAction = AlertAction.withTextField(title: "OK", style: .default, checkFor: self.group.password, noMatchHandler: {
								promptPassword(tried: true)
							})
							var message: String
							if tried {
								message = "Incorrect. "
							} else {
								message = "Group successfully added. "
							}
							message += "Please save the password someplace and enter it in the text field below to confirm that you have it correctly."
							
							vc.alert(title: "Password: \(self.group.password)", message: message, actions: [okAction], textFieldPlaceholder: "")
						}
						promptPassword(tried: false)
					}
				}
			} else {
				let updatedGroup = group.toPFObject()
				updatedGroup.saveInBackground { (success, error) in
					if success {
						print("Successfully updated the group")
						self.groupPageVc.tableView.reloadData()
						self.groupPageVc.title = self.group.name
						self.deleteProgress()
						
						// Update group's posts if necessary
						if let name = self.nameTextField.text, oldName != name {
							print("Updating all posts of \(self.group.name)")
								for post in Post.allPosts.filter({ $0.group == oldName }) {
									post.group = name
									post.toPFObject().saveInBackground { (success, error) in
										if !success {
											print("Save error while updating post \(post.postId) after group name change: \(error?.localizedDescription ?? "unknown error")")
										}
									}
								}
							}
					} else {
						print("Group update error: \(error?.localizedDescription ?? "Unknown error")")
						
						// Reset group info
						self.group.name = oldGroup.name
						self.group.description = oldGroup.description
						self.group.email = oldGroup.email
						self.group.image = oldGroup.image
						self.group.loadedImage = oldGroup.loadedImage
						
						self.displayInNavigationBar(message: "Save failed. Try later.", color: UIColor(red: 0.8, green: 0, blue: 0, alpha: 1))
					}
					if #available(iOS 13.0, *) {
						self.groupPageVc.viewWillAppear(true)
					}
					self.dismiss(animated: true, completion: nil)
				}
			}
		}
		
		// Update group info
		group.name = nameTextField.text ?? ""
		group.description = descriptionTextView.displayText
		group.email = emailTextField.text ?? ""
		
		// Shrink image size if necessary to avoid hitting the max upload size limit for the Parse server
		func cropImage(image: UIImage, minHeightWidthRatio: CGFloat) -> UIImage {
			let imageHeight = image.size.height
			let imageWidth = image.size.width
			if imageHeight / imageWidth > minHeightWidthRatio {
				let cropZone = CGRect(x: 0, y: imageHeight / 2 - imageWidth * minHeightWidthRatio / 2, width: imageWidth, height: imageWidth * minHeightWidthRatio)
				if let cgImage = image.cgImage?.cropping(to: cropZone) {
					return UIImage(cgImage: cgImage)
				}
			}
			return image
		}
		
		func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
			guard image.size.width < newWidth else {
				return image
			}
			
			let scale = newWidth / image.size.width
			let newHeight = image.size.height * scale
			
			UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
			image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
			let newImage = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			
			return newImage!
		}
		
		if imageSelected {
			let minHeightWidthRatio: CGFloat = 160.0 / 375
			// 160 pt: height of the image in Group page vc
			// 375 pt: width of the 5/5s/5c/SE (smallest width of any iPhone with iOS 11 in portrait orientation)
			let image = resizeImage(image: cropImage(image: imageView.image!, minHeightWidthRatio: minHeightWidthRatio), newWidth: 1242)
			group.loadedImage = image
			let imageFile = PFFileObject(data: image.pngData()!)
			// 1242 is the largest width (in pixels) of any iPhone screen so far
			
			/*
			var imageFile: PFFileObject?
			if let imageDimensions = imageView.image?.size, imageDimensions.height / imageDimensions.width > minHeightWidthRatio {
				let cropZone = CGRect(x: 0, y: imageDimensions.height / 2 - imageDimensions.width * minHeightWidthRatio / 2, width: imageDimensions.width, height: imageDimensions.width * minHeightWidthRatio)
				if let cgImage = imageView.image!.cgImage?.cropping(to: cropZone), let data = resizeImage(image: UIImage(cgImage: cgImage), newWidth: 1242).pngData() {
					imageFile = PFFileObject(data: data)
				}
			} else {
				imageFile = PFFileObject(data: imageView.image!.pngData()!)
			}
			*/
			if imageFile != nil {
				imageFile!.saveInBackground { (success, error) in
					if success {
						self.group.image = imageFile
						saveGroup()
					} else {
						print("Failed to save image file: \(error?.localizedDescription ?? "unknown error")")
						self.dismiss(animated: true, completion: nil)
					}
				}
			} else {
				dismiss(animated: true, completion: nil)
			}
		} else {
			group.image = nil
			saveGroup()
		}
	}
	
	// MARK: - Text Fields
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		if let nextTextField = view.viewWithTag(textField.tag + 1) {
			nextTextField.becomeFirstResponder()
		}
		
		return true
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		if let text = textField.text, !text.isEmpty {
			while textField.text!.hasPrefix(" ") {
				textField.text!.removeFirst()
			}
			while textField.text!.hasSuffix(" ") {
				textField.text!.removeLast()
			}
		}
		if let text = textField.text, text != group.name && text != group.email {
			saveProgress()
		}
	}
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		let textView = textView as! DescriptionTextView
		if textView.placeholderOn {
			textView.togglePlaceholder()
		}
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		let textView = textView as! DescriptionTextView
		while textView.text.hasPrefix(" ") {
			textView.text.removeFirst()
		}
		while textView.text.hasSuffix(" ") {
			textView.text.removeLast()
		}
		if textView.text.isEmpty {
			textView.togglePlaceholder()
		}
		if textView.text != group.description {
			saveProgress()
		}
	}
	
	// MARK: - Initialization
	
	enum ActionType {
		case add
		case edit
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		colorBarButtonItems()
		if #available(iOS 13.0, *) {
			isModalInPresentation = true
		}

		tableView.estimatedRowHeight = 95
		tableView.contentInset.bottom = 20
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		imageChanged = false
		if !appearedFirstTime {
			// Scroll to top
			tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
			title = actionType == .add ? "New Group" : "Edit \(group.name)"
			
			// Grab information
			var name: String
			var email: String
			var description: String
			var image: UIImage?

			let base = actionType == .add ? "addGroup" : "group.\(group.groupId)"
			if let info = UserDefaults.standard.stringArray(forKey: "\(base).info") {
				name = info[0]
				email = info[1]
				description = info[2]
				if let imageData = UserDefaults.standard.data(forKey: "\(base).image") {
					image = UIImage(data: imageData)
				}
			} else {
				name = group.name
				email = group.email
				description = group.description
				image = group.loadedImage
			}
			
			// Set up fields
			descriptionTextView.placeholder = "Insert text"
			if description.isEmpty {
				descriptionTextView.placeholderOn = true
				descriptionTextView.togglePlaceholder()
				descriptionTextView.text = description
			} else {
				descriptionTextView.placeholderOn = false
				descriptionTextView.togglePlaceholder()
			}
			emailTextField.text = email
			nameTextField.text = name
			
			// Set up image
			imageSelected = false
			if actionType == .edit, let image = image {
				imageView.contentMode = .scaleAspectFill
				imageRowLabel.backgroundColor = .white
				imageRowLabel.alpha = 0.6
				imageSelected = true
				imageView.image = image
			} else {
				imageView.image = UIImage(named: "photo")
				imageView.contentMode = .center
				imageRowLabel.backgroundColor = .clear
				imageRowLabel.alpha = 1
			}
			self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
			appearedFirstTime = true
			
			tableView.beginUpdates()
			tableView.endUpdates()
			
			// Reset right bar button item
			navigationItem.setRightBarButton(checkButton, animated: false)
			navigationItem.rightBarButtonItem?.isEnabled = true
			navigationItem.leftBarButtonItem?.isEnabled = true
			view.isUserInteractionEnabled = true
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		nameTextField.becomeFirstResponder()
	}

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		switch indexPath.row {
		case 1, 3: return 200
		default: return UITableView.automaticDimension
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.cellForRow(at: indexPath)?.isSelected = false
		if indexPath.row == 1 {
			let photoSourceRequestController = UIAlertController(title: "", message: "Choose an image", preferredStyle: .actionSheet)
			
			let cameraAction = UIAlertAction(title: "From Camera", style: .default, handler: { (action) in
				if UIImagePickerController.isSourceTypeAvailable(.camera) {
					let imagePicker = UIImagePickerController()
					imagePicker.delegate = self
					imagePicker.allowsEditing = true
					imagePicker.sourceType = .camera
					self.imageChanged = true
					
					self.present(imagePicker, animated: true, completion: nil)
				}
			})
			
			let photoLibraryAction = UIAlertAction(title: "From Photo Library", style: .default, handler: { (action) in
				if (UIImagePickerController).isSourceTypeAvailable(.photoLibrary) {
					let imagePicker = UIImagePickerController()
					imagePicker.delegate = self
					imagePicker.allowsEditing = true
					imagePicker.sourceType = .photoLibrary
					self.imageChanged = true
					
					self.present(imagePicker, animated: true, completion: nil)
				}
			})
			
			let noneAction = UIAlertAction(title: "None", style: .default, handler: { (action) in
				self.imageView.image = UIImage(named: "photo")
				self.imageView.contentMode = .center
				self.imageRowLabel.backgroundColor = .clear
				self.imageRowLabel.alpha = 1
				self.imageSelected = false
				self.imageChanged = true
				
				photoSourceRequestController.dismiss(animated: true, completion: nil)
			})
			
			let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
			
			photoSourceRequestController.addAction(cameraAction)
			photoSourceRequestController.addAction(photoLibraryAction)
			photoSourceRequestController.addAction(noneAction)
			photoSourceRequestController.addAction(cancelAction)
			
			// For iPad
			if let popoverController = photoSourceRequestController.popoverPresentationController {
				if let cell = tableView.cellForRow(at: indexPath) {
					popoverController.sourceView = cell
					popoverController.sourceRect = cell.bounds
				}
			}
			
			present(photoSourceRequestController, animated: true, completion: nil)
		} else {
			if nameTextField.isFirstResponder {
				nameTextField.resignFirstResponder()
			} else if emailTextField.isFirstResponder {
				emailTextField.resignFirstResponder()
			} else if descriptionTextView.isFirstResponder {
				descriptionTextView.resignFirstResponder()
			}
		}
	}

	// MARK: - Image Picker
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		
		func fixOrientation(img: UIImage) -> UIImage {
			if (img.imageOrientation == .up) {
				return img
			}
			
			UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
			let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
			img.draw(in: rect)
			
			let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
			UIGraphicsEndImageContext()
			
			return normalizedImage
		}
		
		if let selectedImage = info[.originalImage] as? UIImage {
			imageView.image = fixOrientation(img: selectedImage)
			imageView.contentMode = .scaleAspectFill
			imageRowLabel.backgroundColor = .white
			imageRowLabel.alpha = 0.6
			imageSelected = true
		}
		
		saveProgress()
		dismiss(animated: true, completion: nil)
	}
	
}
