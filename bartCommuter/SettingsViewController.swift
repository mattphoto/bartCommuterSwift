//
//  SettingsViewController.swift
//  bartCommuter
//
//  Created by Matt on 7/26/15.
//  Copyright (c) 2015 Matt. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    var pickerDataSource : [String] = [
        "choose a station",
        "12th St. Oakland City Center",
        "16th St. Mission",
        "19th St. Oakland",
        "24th St. Mission",
        "Ashby",
        "Balboa Park",
        "Bay Fair",
        "Castro Valley",
        "Civic Center / UN Plaza",
        "Coliseum/Oakland Airport",
        "Colma",
        "Concord",
        "Daly City",
        "Downtown Berkeley",
        "Dublin/Pleasanton",
        "El Cerrito del Norte",
        "El Cerrito Plaza",
        "Embarcadero",
        "Fremont",
        "Fruitvale",
        "Glen Park",
        "Hayward",
        "Lafayette",
        "Lake Merritt",
        "MacArthur",
        "Millbrae",
        "Montgomery St.",
        "North Berkeley",
        "North Concord / Martinez",
        "Orinda",
        "Pittsburg / Bay Point",
        "Pleasant Hill",
        "Powell St.",
        "Richmond",
        "Rockridge",
        "San Bruno",
        "San Francisco Int'l Airport",
        "San Leandro",
        "South Hayward",
        "South San Francisco",
        "Union City",
        "Walnut Creek",
        "West Dublin",
        "West Oakland"
    ]
    
    var stationCode : [String] = [
        "",
        "12th",
        "16th",
        "19th",
        "24th",
        "ashb",
        "balb",
        "bayf",
        "cast",
        "civc",
        "cols",
        "colm",
        "conc",
        "daly",
        "dbrk",
        "dubl",
        "deln",
        "plza",
        "embr",
        "frmt",
        "ftvl",
        "glen",
        "hayw",
        "lafy",
        "lake",
        "mcar",
        "mlbr",
        "mont",
        "nbrk",
        "ncon",
        "orin",
        "pitt",
        "phil",
        "powl",
        "rich",
        "rock",
        "sbrn",
        "sfia",
        "sanl",
        "shay",
        "ssan",
        "ucty",
        "wcrk",
        "wdub",
        "woak"
    ]
    
    @IBOutlet weak var trainPicker: UIPickerView!
    @IBOutlet weak var homeStationLabel: UILabel!
    @IBOutlet weak var workStationLabel: UILabel!
    @IBOutlet weak var stationSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.trainPicker.dataSource = self;
        self.trainPicker.delegate = self;

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfComponentsInPickerView(trainPicker: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(trainPicker: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count;
    }
    
    func pickerView(trainPicker: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return pickerDataSource[row]
    }
    
    func pickerView(trainPicker: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        println(stationCode[row])
        
        homeStationLabel.text = pickerDataSource[row]
        
        if(row == 0)
        {
            self.view.backgroundColor = UIColor.whiteColor();
        }
        else if(row == 1)
        {
            self.view.backgroundColor = UIColor.redColor();
        }
        else if(row == 2)
        {
            self.view.backgroundColor =  UIColor.greenColor();
        }
        else
        {
            self.view.backgroundColor = UIColor.whiteColor();
        }
    }

    @IBAction func didTapDoneButton(sender: UIButton) {
        println("done button tapped!")
        
//        NSUserDefaults.standardUserDefaults().setObject(homeStation.text, forKey: "homeStation")
//        NSUserDefaults.standardUserDefaults().setObject(workStation.text, forKey: "workStation")
//        NSUserDefaults.standardUserDefaults().setObject(timeToHomeStation.text.toInt(), forKey: "homeMinutesToStation")
//        NSUserDefaults.standardUserDefaults().setObject(timeToWorkStation.text.toInt(), forKey: "workMinutesToStation")

        dismissViewControllerAnimated(true, completion: nil)
    }
    


}
