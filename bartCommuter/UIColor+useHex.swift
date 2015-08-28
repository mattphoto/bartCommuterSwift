//
//  UIColor+useHex.swift
//  bartCommuter
//
//  Created by Matt on 8/26/15.
//  Copyright (c) 2015 Matt. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    /* Helper function: convert hex to UIColor */
    static func UIColorFromHex(rgbValue : UInt32, alpha : Double = 1.0) -> UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
}

extension UILabel {
    func kern(kerningValue:CGFloat) {
        self.attributedText =  NSAttributedString(string: self.text ?? "", attributes: [NSKernAttributeName:kerningValue, NSFontAttributeName:font, NSForegroundColorAttributeName:self.textColor])
    }
}