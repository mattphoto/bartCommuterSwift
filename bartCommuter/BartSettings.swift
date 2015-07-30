//
//  BartSettings.swift
//  bartCommuter
//
//  Created by Matt on 7/27/15.
//  Copyright (c) 2015 Matt. All rights reserved.
//

import UIKit

class BartSettings: NSObject {
   static let sharedSettings = BartSettings()
    
    var homeStation : String {
        get {
            return NSUserDefaults.standardUserDefaults().objectForKey("homeStation") as! String
        }
    }
}

//        var savedHomeStation = BartSettings.sharedSettings.homeStation
