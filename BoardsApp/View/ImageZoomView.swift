//
//  ImageZoomView.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/19/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit

class ImageZoomView: UIScrollView, UIScrollViewDelegate {
	
	// MARK: - Properties
	
	var imageView: UIImageView!
	var gestureRecognizer: UITapGestureRecognizer!
	
	// MARK: - Initialization
	
	convenience init(frame: CGRect, image: UIImage) {
		self.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
		backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)

		// Image view
		imageView = UIImageView(image: image)
		imageView.frame = frame
		imageView.contentMode = .scaleAspectFit
		addSubview(imageView)

		// Interactions
		setupScrollView()
		setupGestureRecognizer()
		if #available(iOS 13.0, *) {
			CardDetailTableViewController.cardDetailVc.isModalInPresentation = true
		}
	}
	
	func setupScrollView() {
		delegate = self
		minimumZoomScale = 1.0
		maximumZoomScale = 5.0
	}
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return imageView
	}
	
	func setupGestureRecognizer() {
		gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
		gestureRecognizer.numberOfTapsRequired = 1
		addGestureRecognizer(gestureRecognizer)
	}
	
	@objc func handleTap() {
		removeFromSuperview()
		if #available(iOS 13.0, *) {
			CardDetailTableViewController.cardDetailVc.isModalInPresentation = false
		}
	}

}
