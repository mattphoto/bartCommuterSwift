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

    @IBOutlet weak var trainTableView: UITableView!
    
    var cellContent = [1, 2, 3, 4]
    
    struct Train {
        var destination: String = ""
        var destinationCode: String = ""
        var hexColor: String  = ""
        var minutes: Int = -1
        var length: String = ""
    }
    
    var sortedTrainList : [Train] = []
    
    let hour : Int = {
        /* Get current hour */
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.CalendarUnitHour | .CalendarUnitMinute, fromDate: date)
        let hour = components.hour
        return hour
    }()
    
    var timer : NSTimer!
        
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let  savedHomeStation = NSUserDefaults.standardUserDefaults().objectForKey("homeStation") as? String,
                savedWorkStation = NSUserDefaults.standardUserDefaults().objectForKey("workStation") as? String,
                savedHomeMinutesToStation = NSUserDefaults.standardUserDefaults().objectForKey("homeMinutesToStation") as? Int,
                savedWorkMinutesToStation = NSUserDefaults.standardUserDefaults().objectForKey("workMinutesToStation") as? Int
        {
            getTrainDirection()
        } else {
            // No data
            println("no data")
            
            performSegueWithIdentifier("settingsSegue", sender: nil)
        }
        

//        loadSettings()
//        buildTrainsList()
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: "getTrainDirection", userInfo: nil, repeats: true)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cellDisplay : String
        
        if sortedTrainList[indexPath.row].minutes % 2 == 0 {
            let cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier("train", forIndexPath: indexPath) as! TrainTableCell
            cell.backgroundColor = UIColor.grayColor()
            
            cell.textLabel?.text = "\(sortedTrainList[indexPath.row].minutes) min - \(sortedTrainList[indexPath.row].length) cars - \(sortedTrainList[indexPath.row].destination)"
            // heightforrow
            
            return cell
        } else {
            let cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier("chosenTrain", forIndexPath: indexPath) as! ChosenTrainTableCell
            cell.backgroundColor = UIColor.lightGrayColor()
            
            cell.textLabel?.text = "\(sortedTrainList[indexPath.row].minutes) min - \(sortedTrainList[indexPath.row].length) cars - \(sortedTrainList[indexPath.row].destination)"
            // heightforrow
            
            return cell

        }
        
//        let cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier("train", forIndexPath: indexPath) as! ChosenTrainTableCell
//        cell.backgroundColor = UIColor.g
//        
//
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedTrainList.count
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
    
    // MARK: - Get Train Direction
    
    func getTrainDirection() {
        
        var savedHomeStation = NSUserDefaults.standardUserDefaults().objectForKey("homeStation") as! String? ?? "WOAK"
        var savedWorkStation = NSUserDefaults.standardUserDefaults().objectForKey("workStation") as! String? ?? "EMBR"
        var savedHomeMinutesToStation = NSUserDefaults.standardUserDefaults().objectForKey("homeMinutesToStation") as! Int? ?? 5
        var savedWorkMinutesToStation = NSUserDefaults.standardUserDefaults().objectForKey("workMinutesToStation") as! Int? ?? 5
        var savedMidday = 13
        
        println(savedWorkStation)
        println(savedHomeStation)
        println(savedHomeMinutesToStation)
        println(savedWorkMinutesToStation)
        println(savedMidday)

        
        let BASE_URL = "http://api.bart.gov/api/sched.aspx"
        let CMD = "depart"
        let ORIG = "EMBR"
        let DEST = "WOAK"
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
            NSOperationQueue.mainQueue().addOperationWithBlock({
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
            })
            
        }
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }
    
    // MARK: - Build Trains List
    
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
            NSOperationQueue.mainQueue().addOperationWithBlock({

                if let error = downloadError {
                    println("Could not complete the request \(error)")
                } else {
                    /* 5 - Success! Parse the data */
                    var parsingError: NSError? = nil
                    
                    var returnedData = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
                    
                    var xml = SWXMLHash.parse(returnedData)
                    
                    var etds = xml["root"]["station"]["etd"]
                
                    
                    var trainsList : [Train] = []

                    println(trainDirections)
                    
                    for etd in etds{
                        var train = Train()

                        if let i = find(trainDirections, etd["abbreviation"].element!.text!) {
                            
                            var estimates = etd["estimate"]
                            for estimate in estimates {
                                
                                train.destination = etd["destination"].element!.text!
                                train.destinationCode = etd["abbreviation"].element!.text!
                                train.length = estimate["length"].element!.text!
                                train.hexColor = estimate["hexcolor"].element!.text!
                                
                                var trainMinutes = estimate["minutes"].element!.text!
                                if trainMinutes != "Leaving" {
                                    train.minutes = (estimate["minutes"].element!.text!).toInt()!
                                } else {
                                    train.minutes = 0
                                }
                                trainsList.append(train)

                            }  // for estimate in estimates
                        } // if let i = find(trainDirections
                    } // for  etd in etds
                    
                    trainsList.sort({ $0.minutes < $1.minutes }) // magical!

                    self.sortedTrainList = trainsList
                    self.trainTableView.reloadData()
                    
                    for train in trainsList {
                        println("Train: \(train.minutes) \(train.destination) \(train.destinationCode) \(train.length) \(train.hexColor)")
                    }
                    

                } // if let api call
            })

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

