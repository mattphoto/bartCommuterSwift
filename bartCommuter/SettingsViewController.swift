//
//  SettingsViewController.swift
//  bartCommuter
//
//  Created by Matt on 7/26/15.
//  Copyright (c) 2015 Matt. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var homeStation: UITextField!
    
    @IBOutlet weak var workStation: UITextField!
    
    @IBOutlet weak var timeToHomeStation: UITextField!
    
    @IBOutlet weak var timeToWorkStation: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapDoneButton(sender: UIButton) {
        println("done button tapped!")
        
        NSUserDefaults.standardUserDefaults().setObject(homeStation.text, forKey: "homeStation")
        NSUserDefaults.standardUserDefaults().setObject(workStation.text, forKey: "workStation")
        NSUserDefaults.standardUserDefaults().setObject(timeToHomeStation.text.toInt(), forKey: "homeMinutesToStation")
        NSUserDefaults.standardUserDefaults().setObject(timeToWorkStation.text.toInt(), forKey: "workMinutesToStation")

        dismissViewControllerAnimated(true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
