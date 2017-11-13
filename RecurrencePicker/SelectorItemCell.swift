//
//  SelectorItemCell.swift
//  RecurrencePicker
//
//  Created by Xin Hong on 16/4/7.
//  Copyright © 2016年 Teambition. All rights reserved.
//

import UIKit

internal class SelectorItemCell: UICollectionViewCell {
    @IBOutlet weak var textLabel: UILabel!

    internal fileprivate(set) var isItemSelected = false

    override func awakeFromNib() {
        super.awakeFromNib()
        setItemSelected(false)
    }

    internal func setItemSelected(_ selected: Bool) {
        isItemSelected = selected
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
			backgroundColor = selected ? UIColor.white.withAlphaComponent(0.08) : UIColor.white.withAlphaComponent(0.04)
			textLabel.textColor = UIColor.white.withAlphaComponent(0.8)
		}else{
			backgroundColor = selected ? UIColor.black.withAlphaComponent(0.08) : UIColor.black.withAlphaComponent(0.04)
			textLabel.textColor = UIColor.black.withAlphaComponent(0.8)
		}
    }
}
