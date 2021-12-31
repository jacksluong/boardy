//
//  WalkthroughView.swift
//  BoardsApp
//
//  Created by Jacky Luong on 8/10/19.
//  Copyright © 2019 Jacky Luong. All rights reserved.
//

import UIKit

class WalkthroughView: UIView {

	@IBOutlet var holeViews: [UIView]!
	@IBOutlet var stepLabels: [UILabel]!
	
	var step = 0
    
	@IBAction func walkthroughViewTapped(_ sender: Any) {
		step += 1
		if step == stepLabels.count {
			UIView.animate(withDuration: 0.4, animations: {
				self.alpha = 0
			}) { _ in
				self.removeFromSuperview()
				UserDefaults.standard.set(true, forKey: "walkthroughed")
				print(UserDefaults.standard.bool(forKey: "walkthroughed"))
			}
		} else {
			self.setNeedsDisplay()
		}
	}
	
	// MARK: - Drawing

    override func draw(_ rect: CGRect) {
        super.draw(rect)

		if step > 0 && step < holeViews.count + 1 {
			// Ensures to use the current background color to set the filling color
			backgroundColor?.setFill()
			UIRectFill(rect)

			let layer = CAShapeLayer()
			let path = CGMutablePath()

			// Make hole in view's overlay
			// NOTE: Here, instead of using the transparentHoleView UIView we could use a specific CGRect location instead
			let rect = UIBezierPath(roundedRect: holeViews[step - 1].frame, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 10, height: 10))
			path.addRect(rect.bounds)
			path.addRect(bounds)

			layer.path = path
			layer.fillRule = .evenOdd
			self.layer.mask = layer
		}
		
		if step != 0 {
			stepLabels[step - 1].isHidden = true
		}
		stepLabels[step].isHidden = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    // MARK: - Initialization

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		for view in holeViews {
			view.backgroundColor = .clear
		}
		
		for label in stepLabels {
			label.isHidden = true
		}
	}
}
