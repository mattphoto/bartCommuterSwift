//
//  ViewController.swift
//  bartCommuter
//
//  Created by Matt on 7/13/15.
//  Copyright (c) 2015 Matt. All rights reserved.
//

import UIKit
import Foundation
import SWXMLHash

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var cellContent = [1, 2, 3, 4]
    
    let hour : Int = {
        /* Get current hour */
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.CalendarUnitHour | .CalendarUnitMinute, fromDate: date)
        let hour = components.hour
        return hour
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //            NSUserDefaults.standardUserDefaults().setObject("WOAK", forKey: "homeStation")
        //            NSUserDefaults.standardUserDefaults().setObject("EMBR", forKey: "workStation")
        //            NSUserDefaults.standardUserDefaults().setObject(12, forKey: "homeMinutesToStation")
        //            NSUserDefaults.standardUserDefaults().setObject(11, forKey: "workMinutesToStation")
        var savedHomeStation = NSUserDefaults.standardUserDefaults().objectForKey("homeStation") as! String
        var savedWorkStation = NSUserDefaults.standardUserDefaults().objectForKey("workStation") as! String
        var savedHomeMinutesToStation = NSUserDefaults.standardUserDefaults().objectForKey("homeMinutesToStation") as! Int
        var savedWorkMinutesToStation = NSUserDefaults.standardUserDefaults().objectForKey("workMinutesToStation") as! Int
//        println(savedHomeStation)
//        println(savedWorkStation)
//        println(savedHomeMinutesToStation)
//        println(savedWorkMinutesToStation)
        
//        loadSettings()
        getTrainDirection()
//        buildTrainsList()
        
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier("train", forIndexPath: indexPath) as! UITableViewCell
        cell.backgroundColor = UIColor.yellowColor()
        
        
        cell.textLabel?.text = "blah"
        // heightforrow
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }

    

    func loadSettings(){
    
        println(self.hour)
    }
    
    
    func getTrainDirection() {
        
        let BASE_URL = "http://api.bart.gov/api/sched.aspx"
        let CMD = "depart"
        let ORIG = "WOAK"
        let DEST = "EMBR"
        let KEY = "Z5LP-U799-IDSQ-DT35"
        let DATE = "now"
        let B = 2
        let A = 4
        
        /* 2 - API method arguments */
        let methodArguments = [
            "cmd": CMD,
            "orig": ORIG,
            "dest": DEST,
            "key": KEY,
            "date": DATE,
            "b": B,
            "a": A
        ]
        
        /* 3 - Initialize session and url */
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments as! [String : AnyObject])
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        /* 4 - Initialize task for getting data */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                println("Could not complete the request \(error)")
            } else {
                /* 5 - Success! Parse the data */
                var parsingError: NSError? = nil
                
                var returnedData = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
                
                var xml = SWXMLHash.parse(returnedData)

                var trainDirections : [String] = []

                for elem in xml["root"]["schedule"]["request"] {
                    var trips = elem["trip"]
                    for trip in trips {
                        var trainHead = trip["leg"].element!.attributes["trainHeadStation"]!
                            trainDirections.append(trainHead)
                    }
                }

                self.buildTrainsList(trainDirections)
            }
            
        }
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }
    
    
    func buildTrainsList(trainDirections: [String]) {
        
        println(trainDirections)
        let BASE_URL = "http://api.bart.gov/api/etd.aspx"
        let CMD = "etd"
        let ORIG = "EMBR"
        let KEY = "Z5LP-U799-IDSQ-DT35"
        
        /* 2 - API method arguments */
        let methodArguments = [
            "cmd": CMD,
            "orig": ORIG,
            "key": KEY
        ]
        
        /* 3 - Initialize session and url */
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        /* 4 - Initialize task for getting data */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                println("Could not complete the request \(error)")
            } else {
                /* 5 - Success! Parse the data */
                var parsingError: NSError? = nil
                
                var returnedData = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
                
                var xml = SWXMLHash.parse(returnedData)
                
                var etds = xml["root"]["station"]["etd"]
                
                var trainsList : [String] = []
//                println(xml)
//                println()
//                println()

                for etd in etds{
                    var train : [String] = []

                    println(trainDirections)
                    
                    if let i = find(trainDirections, etd["abbreviation"].element!.text!) {

                    
                    
                        train.append(etd["destination"].element!.text!)
                        train.append(etd["abbreviation"].element!.text!)

    //                    trainDirections
                        var estimates = etd["estimate"]
                        for estimate in estimates {
                            
                            train.append(estimate["length"].element!.text!)
                            train.append(estimate["hexcolor"].element!.text!)
                            train.append(estimate["minutes"].element!.text!)

                            
                            println(train)

                            
                            
    //                    var estimates = etd["estimate"]["minutes"]
                        println(estimate["minutes"].element!.text!)
                        }
                    }
                } // for in etd

            } // if let api call
        } // session.dataTaskWithRequest
        
       //  8 - Sort the list of trains

//        var sortedTrainsList = sorted(TrainsList, { (first : Int, second : Int ) -> Bool in
//                return first < second
//            })
//        
        
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
}

