//
//  TextFieldCell.swift
//  CellAnimation
//
//  Created by Göran Lilja on 2017-03-21.
//  Copyright © 2017 Familjen Lilja. All rights reserved.
//

import UIKit

class TextFieldCell: UITableViewCell {

    @IBOutlet weak var textField: UITextField!
    
    var isAnimating = false
    
    override func layoutSubviews() {
        UIView.animate(withDuration: animationDuration) {
            self.contentView.layoutIfNeeded()
        }
    }
}
