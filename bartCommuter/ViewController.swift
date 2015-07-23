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
        var cellDisplay : String
        
        // if row is odd, then cellDisplay = train
        // if row is even then cellDisplay = chosenTrain
        
        
//        let cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier("train", forIndexPath: indexPath) as! ChosenTrainTableCell
//        cell.backgroundColor = UIColor.yellowColor()
//        
//
        let cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier("train", forIndexPath: indexPath) as! TrainTableCell
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
    func getApiKey() -> String {
        let pListPath = NSBundle.mainBundle().pathForResource("apiKey", ofType: "plist")
        let pListKey = NSDictionary(contentsOfFile: pListPath!)
        let KEY = pListKey!["APIKEY"]! as! String
        return KEY
    }
    
    func getTrainDirection() {
        
        let BASE_URL = "http://api.bart.gov/api/sched.aspx"
        let CMD = "depart"
        let ORIG = "WOAK"
        let DEST = "EMBR"
        let KEY = getApiKey()
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
        
        let BASE_URL = "http://api.bart.gov/api/etd.aspx"
        let CMD = "etd"
        let ORIG = "EMBR"
        let KEY = getApiKey()
        
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
                
                struct Train {
                    var destination: String = ""
                    var destinationCode: String = ""
                    var hexColor: String  = ""
                    var minutes: Int = -1
                    var length: String = ""
                }
                
                var trainsList : [Train] = []

                println(trainDirections)
                
                /* var trainList : [train] */
                
                for etd in etds{
                    var train = Train()

                    
                    if let i = find(trainDirections, etd["abbreviation"].element!.text!) {
                        
                        var estimates = etd["estimate"]
                        for estimate in estimates {
                            train.destination = etd["destination"].element!.text!
                            train.destinationCode = etd["abbreviation"].element!.text!
                            train.length = estimate["length"].element!.text!
                            train.hexColor = estimate["hexcolor"].element!.text!
                            train.minutes = (estimate["minutes"].element!.text!).toInt()!

                            trainsList.append(train)

//                            println(train.destination)
//                            println(train.destinationCode)
//                            println(train.length)
//                            println(train.hexColor)
//                            println(train.minutes)
//
//                            println(train)
    //                    var estimates = etd["estimate"]["minutes"]
                        }  // for estimate in estimates
                    } // if let i = find(trainDirections
                } // for  etd in etds
                
                trainsList.sort({ $0.minutes < $1.minutes }) // magical!

                for train in trainsList {
                    println("Train: \(train.minutes) \(train.destination) \(train.destinationCode) \(train.length) \(train.hexColor)")
                }

//                  8 - Sort the list of trains
//                WHY DOESN'T THIS WORK? --------------------------------------
//                var sortedTrainsList = sorted(trainsList, { (a.minutes : Int, b.minutes : Int ) -> Bool in
//                    return a.minutes < b.minutes
//                })
//                println(sortedTrainsList)
                
                
//                println(trainsList)
//                println(trainsList[0].minutes)

            } // if let api call
        } // session.dataTaskWithRequest
        
        
        
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

