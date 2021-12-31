//
//  InsetsLabel.swift
//  BoardsApp
//
//  Created by Jacky Luong on 7/30/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit

class InsetsLabel: UILabel {
	
	let insets = UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 10)
	
	override func drawText(in rect: CGRect) {
		super.drawText(in: rect.inset(by: insets))
	}
	
	override var intrinsicContentSize: CGSize {
		var size = super.intrinsicContentSize
		size.width += insets.left * 2
		return size;
	}

}
