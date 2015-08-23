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
    
    var stationSegmentedSelection = "home"
    var homeStation = ""
    var workStation = ""
    @IBOutlet weak var trainPicker: UIPickerView!
    @IBOutlet weak var homeStationLabel: UILabel!
    @IBOutlet weak var workStationLabel: UILabel!
    @IBOutlet weak var homeTimeLabel: UILabel!
    @IBOutlet weak var workTimeLabel: UILabel!
    @IBOutlet weak var stationSegmentedControl: UISegmentedControl!
    @IBOutlet weak var homeTimeStepper: UIStepper!
    @IBOutlet weak var workTimeStepper: UIStepper!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.trainPicker.dataSource = self;
        self.trainPicker.delegate = self;

        homeTimeStepper.maximumValue = 59
        workTimeStepper.maximumValue = 59
        homeTimeStepper.value = 5
        workTimeStepper.value = 5

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
        if stationSegmentedSelection == "home" {
            homeStationLabel.text = pickerDataSource[row]
            homeStation = stationCode[row]
        } else if stationSegmentedSelection == "work" {
            workStationLabel.text = pickerDataSource[row]
            workStation = stationCode[row]
        }
    }

    @IBAction func homeOrWorkStation(sender: UISegmentedControl) {
        switch stationSegmentedControl.selectedSegmentIndex
        {
        case 0:
            stationSegmentedSelection = "home"
        case 1:
            stationSegmentedSelection = "work"
        default:
            break; 
        }
    }
    
    @IBAction func homeStepperValueChanged(sender: UIStepper) {
        homeTimeLabel.text = Int(sender.value).description
    }
    
    @IBAction func workStepperValueChanged(sender: UIStepper) {
        workTimeLabel.text = Int(sender.value).description
    }
    
    @IBAction func didTapDoneButton(sender: UIButton) {
        println("done button tapped!")
        
        NSUserDefaults.standardUserDefaults().setObject(homeStation, forKey: "homeStation")
        NSUserDefaults.standardUserDefaults().setObject(workStation, forKey: "workStation")
        NSUserDefaults.standardUserDefaults().setObject(homeTimeLabel.text!.toInt(), forKey: "homeMinutesToStation")
        NSUserDefaults.standardUserDefaults().setObject(workTimeLabel.text!.toInt(), forKey: "workMinutesToStation")
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}
