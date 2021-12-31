//
//  PostFormTableViewController.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/6/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit
import Parse

class PostFormTableViewController: UITableViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {

	// MARK: - Outlets
	
	@IBOutlet var checkButton: UIBarButtonItem!
	@IBOutlet var imageView: UIImageView!
	
	@IBOutlet var imageRowLabel: UILabel! {
		didSet {
			imageRowLabel.bounds.inset(by: UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0))
		}
	}
	@IBOutlet var selectedTimeLabel: UILabel!
	@IBOutlet var timeExtraInfo: UILabel!
	@IBOutlet var descriptionExtraInfo: UILabel!
	
	@IBOutlet var timePicker: UIDatePicker!
	@IBOutlet var titleTextField: RoundedTextField! {
		didSet {
			titleTextField.delegate = self
			titleTextField.autocapitalizationType = .words
		}
	}
	@IBOutlet var locationTextField: RoundedTextField! {
		didSet {
			locationTextField.delegate = self
			locationTextField.autocapitalizationType = .sentences
		}
	}
	@IBOutlet var descriptionTextView: DescriptionTextView! {
		didSet {
			descriptionTextView.delegate = self

		}
	}
	
	// MARK: - Properties
	
	static var postFormVc: PostFormTableViewController {
		return (myNavigationController.viewControllers.first as! PostFormTableViewController)
	}
	static var myNavigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "leadToPostForm") as! UINavigationController // a reference to keep the navigation controller from deinitializing
	
	var groupPageVc: GroupPageViewController!
	var actionType: ActionType!
	var post: Post!
	var appearedFirstTime = false // distinguishes whether it appeared after the image picker or from the group page
	private var imageSelected = false
	private var imageChanged = false
	
	// MARK: - Actions
	
	@IBAction func timePickerDidChange(_ datePicker: UIDatePicker) {
		timePicker.minimumDate = Date(timeIntervalSinceNow: 0)
		
		let selectedTime = SimpleDate(from: timePicker.date)
		var time = selectedTime.description
		if post.type == .event && selectedTime.clockTime == (0, 0) {
			time.removeLast(9)
		}
		selectedTimeLabel.text = time
		saveProgress()
	}
	
	@IBAction func cancelButtonClicked(_ sender: Any) {
		let noAction = AlertAction.cancel("No")
		let yesAction = AlertAction.normal(UIAlertAction(title: "Yes", style: .default) { _ in
			self.deleteProgress()
			self.dismiss(animated: true, completion: nil)
		})
		alert(title: actionType == .edit ? "Discard Changes?" : "Discard Post?", message: actionType == .edit ? "All unsaved changes will be lost." : "All provided information will not be saved.", actions: [noAction, yesAction])
	}
	
	func saveProgress() {
		// Save all provided information in case saving to the server fails
		let base = actionType == .add ? "addPost" : "post.\(post.postId)"
		UserDefaults.standard.set([titleTextField.text!, locationTextField.text ?? "", descriptionTextView.displayText], forKey: "\(base).info")
		UserDefaults.standard.set(SimpleDate(from: timePicker.date).arrayForm, forKey: "\(base).date")
		if imageSelected, let imageData = imageView.image?.pngData() {
			UserDefaults.standard.set(imageData, forKey: "\(base).image")
		}
		
		if actionType == .add {
			UserDefaults.standard.set("\(post.group)\(post.type.rawValue)", forKey: "addPost.group")
		}
	}
	
	func deleteProgress() {
		let base = actionType == .add ? "addPost" : "post.\(post.postId)"
		UserDefaults.standard.removeObject(forKey: "\(base).info")
		UserDefaults.standard.removeObject(forKey: "\(base).date")
		UserDefaults.standard.removeObject(forKey: "\(base).image")
		
		if actionType == .add {
			UserDefaults.standard.removeObject(forKey: "addPost.group")
		}
	}
	
	@IBAction func submitButtonClicked(_ sender: Any) {
		if actionType == .edit && post.title == titleTextField.text && post.time == SimpleDate(from: timePicker.date) && post.location == locationTextField.text && post.description == descriptionTextView.text && !imageChanged {
			// No info changed
			dismiss(animated: true, completion: nil)
			return
		}
		
		func qualityCheck() -> Bool {
			// Check if all requirements are met
			if  post.type != .meeting && descriptionTextView.text.count < 12 {
				alert(title: "Invalid Description", message: "Please provide a more detailed description about this post for viewers.", actions: [])
				return false
			}
			if post.type == .event && titleTextField.text!.count < 4 {
				alert(title: "Invalid Title", message: "The event title must have a minimum of 4 characters.", actions: [])
				return false
			}
			if groupPageVc.posts.count == 0 {
				return true
			}
			
			let currentIndex: Int? = groupPageVc.posts.firstIndex(of: post)
			
			var postsThatDay = 0
			for i in 0...(groupPageVc.posts.count - 1) {
				if i == currentIndex {
					continue
				}
				
				// Check title similiarity
				var sameWords = 0
				let wordsA = groupPageVc.posts[i].title.split(separator: " ")
				let wordsB = titleTextField.text!.split(separator: " ")
				for word in wordsA.count > wordsB.count ? wordsA : wordsB {
					if (wordsA.count > wordsB.count ? wordsB : wordsA).contains(word) {
						sameWords += 1
					}
				}
				if Double(sameWords) / Double((wordsA.count > wordsB.count ? wordsA : wordsB).count) >= 0.75 {
					alert(title: "Suspicion of Spam", message: "This title appears very similar to another post by \(post.group). Duplicate posts are not allowed.", actions: [])
					return false
				}
				
				// Check time similarity
				let existingTime = groupPageVc.posts[i].time
				let newTime = SimpleDate(from: timePicker.date)
				if existingTime.calendarTime == newTime.calendarTime && abs((existingTime.clockTime.hour * 60 + existingTime.clockTime.minute) - (newTime.clockTime.hour * 60 + newTime.clockTime.minute)) < 60 {
					alert(title: "Suspicion of Spam", message: "The selected time is very similar to another post by \(post.group). Duplicate posts are not allowed.", actions: [])
					return false
				}
				
				// Check number of events that day
				if existingTime.calendarTime == newTime.calendarTime {
					if postsThatDay == 2 {
						alert(title: "Limit Reached", message: "All groups are limited to three posts on the same day to prevent spam.", actions: [])
						return false
					} else {
						postsThatDay += 1
					}
				}
			}
			
			return true
		}
		
		func indicateActivity() {
			let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
			let barButton = UIBarButtonItem(customView: activityIndicator)
			navigationItem.setRightBarButton(barButton, animated: true)
			activityIndicator.startAnimating()
			navigationItem.rightBarButtonItem?.isEnabled = false
			navigationItem.leftBarButtonItem?.isEnabled = false
			view.isUserInteractionEnabled = false
			self.title = "Saving..."
		}
		
		// Update post with new information
		switch post.type {
		case .announcement:
			guard !descriptionTextView.placeholderOn else {
				alert(title: "Missing Information", message: "Please provide text in the fields marked as required.", actions: [])
				return
			}
			if !qualityCheck() {
				return
			}
			indicateActivity()
			
			// Update info
			post.title = titleTextField.text!
			post.description = descriptionTextView.displayText
			if imageSelected, let image = imageView.image {
				post.image = PFFileObject(data: image.pngData()!)
				post.loadedImage = image
			} else {
				post.image = nil
				post.loadedImage = nil
			}
		case .event:
			guard let titleText = titleTextField.text, let locationText = locationTextField.text, !titleText.isEmpty && !locationText.isEmpty, !descriptionTextView.placeholderOn else {
				alert(title: "Missing Information", message: "Please provide text in the fields marked as required.", actions: [])
				return
			}
			if !qualityCheck() {
				return
			}
			indicateActivity()
			
			// Update info
			post.title = titleTextField.text ?? ""
			post.description = descriptionTextView.displayText
			post.location = locationTextField.text ?? ""
			if imageSelected, let image = imageView.image {
				post.image = PFFileObject(data: image.pngData()!)
				post.loadedImage = image
			} else {
				post.image = nil
				post.loadedImage = nil
			}
		case .meeting:
			guard let text = locationTextField.text, !text.isEmpty else {
				alert(title: "Missing Information", message: "Please provide text in the fields marked as required.", actions: [])
				return
			}
			if !qualityCheck() {
				return
			}
			indicateActivity()
			
			// Update info
			post.title = titleTextField.text ?? ""
			post.description = descriptionTextView.displayText
			post.location = locationTextField.text ?? ""
		}
		post.time = SimpleDate(from: timePicker.date)
		
		// Save the post itself
		if actionType == .add {
			let newPost = post.toNewPFObject()
			newPost.saveInBackground { (success, error) in
				if success {
					print("Successfully added the post")
					self.post.postId = newPost.objectId!
					Post.allPosts.append(self.post)
					self.groupPageVc.updateData()
					self.groupPageVc.updateAtIndex = self.groupPageVc.posts.firstIndex(of: self.post)!
					self.deleteProgress()
				} else {
					print("Save error: \(error?.localizedDescription ?? "unknown error")")
					self.displayInNavigationBar(message: "Save failed.", color: UIColor(red: 0.8, green: 0, blue: 0, alpha: 1))
				}
				if #available(iOS 13.0, *) {
					self.groupPageVc.viewWillAppear(true)
				}
				self.dismiss(animated: true, completion: nil)
			}
		} else {
			let updatedPost = post.toPFObject()
			updatedPost.saveInBackground { (success, error) in
				if success {
					print("Successfully updated the post")
					self.groupPageVc.updateData()
					self.groupPageVc.updateAtIndex = self.groupPageVc.posts.firstIndex(of: self.post)!
					self.deleteProgress()
				} else {
					print("Post update error: \(error?.localizedDescription ?? "Unknown error")")
					updatedPost.saveEventually()
					self.displayInNavigationBar(message: "Save failed.", color: UIColor(red: 0.8, green: 0, blue: 0, alpha: 1))
					return
				}
				if #available(iOS 13.0, *) {
					self.groupPageVc.viewWillAppear(true)
				}
				self.dismiss(animated: true, completion: nil)
			}
		}
	}
	
	// MARK: - Text Fields
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		let increase = (post.type == .announcement && textField.tag == 0) ? 2 : 1
		if let nextTextField = view.viewWithTag(textField.tag + increase) {
			nextTextField.becomeFirstResponder()
		}
		
		return true
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		if let text = textField.text, text.isEmpty {
			while text.hasPrefix(" ") {
				textField.text!.removeFirst()
			}
			while text.hasSuffix(" ") {
				textField.text!.removeLast()
			}
		}
		if let text = textField.text, text != post.title && text != post.location {
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
		if textView.text != post.description {
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
			title = "\(actionType == .add ? "New" : "Edit") " +  "\(post.type)".capitalized
			
			// Grab information
			var title: String
			var location: String
			var description: String
			var date: SimpleDate
			var image: UIImage?
			
			let base = actionType == .add ? "addPost" : "post.\(post.postId)"
			if let info = UserDefaults.standard.stringArray(forKey: "\(base).info") {
				title = info[0]
				location = info[1]
				description = info[2]
				date = SimpleDate(from: UserDefaults.standard.array(forKey: "\(base).date") as! [Int])
				if let imageData = UserDefaults.standard.data(forKey: "\(base).image") {
					image = UIImage(data: imageData)
				}
			} else {
				title = post.title
				location = post.location
				description = post.description
				if actionType == .edit {
					date = post.time
				} else {
					date = SimpleDate.now.forward(by: 7, .day)
					date.clockTime = (12, 0)
				}
				image = post.loadedImage
			}
			
			// Set up fields
			timePicker.minimumDate = Date(timeIntervalSinceNow: 0)
			switch post.type {
			case .announcement:
				timePicker.maximumDate = SimpleDate.now.forward(by: 1, .month).dateForm
				
				timeExtraInfo.text = "This announcement will expire and delete after the selected time. Limited to one month ahead."
				titleTextField.placeholder = "(Optional)"
				descriptionTextView.placeholder = "(Required)"
				descriptionExtraInfo.isHidden = true
			case .event:
				timePicker.maximumDate = SimpleDate.now.forward(by: 12, .month).dateForm
				
				timeExtraInfo.text = "To display only the date, change the time to 12:00 AM. Limited to one year ahead."
				titleTextField.placeholder = "(Required)"
				locationTextField.text = location
				locationTextField.placeholder = "(Required)"
				descriptionTextView.placeholder = "(Required)"
				descriptionExtraInfo.isHidden = true
			case .meeting:
				timePicker.maximumDate = SimpleDate.now.forward(by: 3, .month).dateForm
				
				timeExtraInfo.text = "Limited to three months ahead."
				titleTextField.placeholder = "(Optional)"
				locationTextField.text = location
				locationTextField.placeholder = "(Required) Ex. B334, Mr. X's room, etc."
				descriptionTextView.placeholder = "(Optional)"
				descriptionExtraInfo.isHidden = false
			}
			descriptionTextView.placeholderOn = true
			if !description.isEmpty {
				descriptionTextView.togglePlaceholder()
				descriptionTextView.text = description
			} else {
				descriptionTextView.placeholderOn = false
				descriptionTextView.togglePlaceholder()
			}
			titleTextField.text = title
			
			// Set up image & date picker
			imageSelected = false
			if actionType == .edit {
				if let image = image {
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
			} else {
				if post.type != .meeting {
					imageView.image = UIImage(named: "photo")
					imageView.contentMode = .center
					imageRowLabel.backgroundColor = .clear
					imageRowLabel.alpha = 1
				}
			}
			timePicker.setDate(date.dateForm, animated: false)
			let selectedTime = SimpleDate(from: timePicker.date)
			var time = selectedTime.description
			if post.type == .event && selectedTime.clockTime == (0, 0) {
				time.removeLast(9)
			}
			selectedTimeLabel.text = time
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
		titleTextField.becomeFirstResponder()
	}
	
	// MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		switch indexPath.row {
		case 0: return UITableView.automaticDimension
		case 1: return post.type == .meeting ? 0 : 200
		case 2: return UITableView.automaticDimension
		case 3: return post.type == .announcement ? 0 : UITableView.automaticDimension
		default: return 200
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
			if titleTextField.isFirstResponder {
				titleTextField.resignFirstResponder()
			} else if locationTextField.isFirstResponder {
				locationTextField.resignFirstResponder()
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
