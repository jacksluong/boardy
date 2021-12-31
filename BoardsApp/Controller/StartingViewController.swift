//
//  StartingViewController.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/29/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit
import Parse

class StartingViewController: UIViewController {

	@IBOutlet var taskLabel: UILabel!
	@IBOutlet var activityIndicatorView: UIActivityIndicatorView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		navigationController?.setNavigationBarHidden(true, animated: false)
		taskLabel.text = "Loading posts"
	}
	
	override func viewDidAppear(_ animated: Bool) {
		AppDelegate.loadDataFromParse(withCachePolicy: .networkElseCache, caller: self)
	}

}
