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
    
    // main running loop
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let  savedHomeStation = NSUserDefaults.standardUserDefaults().objectForKey("homeStation") as? String,
                savedWorkStation = NSUserDefaults.standardUserDefaults().objectForKey("workStation") as? String,
                savedHomeMinutesToStation = NSUserDefaults.standardUserDefaults().objectForKey("homeMinutesToStation") as? Int,
                savedWorkMinutesToStation = NSUserDefaults.standardUserDefaults().objectForKey("workMinutesToStation") as? Int
        {
        // if all 4 user defaults exist...
            // determine origin and destination based on hourToReverseDirection
            let hourToReverseDirection = NSUserDefaults.standardUserDefaults().objectForKey("hourToReverseDirection") as! Int? ?? 13

            // it's commute to work if it's less than midday && later than 3am
            if (self.hour < hourToReverseDirection) && (self.hour > 3) {
                NSUserDefaults.standardUserDefaults().setObject(savedHomeStation, forKey: "origin")
                NSUserDefaults.standardUserDefaults().setObject(savedWorkStation, forKey: "destination")
                NSUserDefaults.standardUserDefaults().setObject(savedHomeMinutesToStation, forKey: "minutesToOrigin")
                NSUserDefaults.standardUserDefaults().setObject(savedWorkMinutesToStation, forKey: "minutesToDestination")
            } else {
            // it's commute to home
                NSUserDefaults.standardUserDefaults().setObject(savedHomeStation, forKey: "destination")
                NSUserDefaults.standardUserDefaults().setObject(savedWorkStation, forKey: "origin")
                NSUserDefaults.standardUserDefaults().setObject(savedHomeMinutesToStation, forKey: "minutesToDestination")
                NSUserDefaults.standardUserDefaults().setObject(savedWorkMinutesToStation, forKey: "minutesToOrigin")
            }
            getServiceAdvisory()
            getTrainDirection()

        } else {
        // present user with a settings modal
            performSegueWithIdentifier("settingsSegue", sender: nil)
        }

        self.timer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: "getTrainDirection", userInfo: nil, repeats: true)
    }
    
    // Select TableView
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cellDisplay : String
        let etdIndicatorColors : [UInt32] = [0xe51c23, 0xff9800, 0x259b24, 0x009688, 0x00BCD4, 0x03a9f4, 0x5677fc, 0x3f51b5, 0x3f51b5, 0x3f51b5, 0x3f51b5, 0x3f51b5, 0x3f51b5, 0x3f51b5]
    
        if indexPath.row != 3 {
            let cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier("train", forIndexPath: indexPath) as! TrainTableCell
            cell.backgroundColor = UIColorFromHex(etdIndicatorColors[indexPath.row])
            cell.textLabel?.text = "\(sortedTrainList[indexPath.row].minutes) min - \(sortedTrainList[indexPath.row].length) cars - \(sortedTrainList[indexPath.row].destination)"
            cell.textLabel?.textColor = UIColorFromHex(etdIndicatorColors[indexPath.row + 1])
            return cell
        } else {
            let cell : ChosenTrainTableCell = tableView.dequeueReusableCellWithIdentifier("chosenTrain", forIndexPath: indexPath) as! ChosenTrainTableCell
            cell.backgroundColor = UIColor.lightGrayColor()
            cell.chosenTrainLabel?.text = "\(sortedTrainList[indexPath.row].minutes)"
            return cell
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedTrainList.count
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row != 4 {
            return 36
        } else {
            return 400
        }
    }
    
    // get API key from plist that's .gitignored
    func getApiKey() -> String {
        let pListPath = NSBundle.mainBundle().pathForResource("apiKey", ofType: "plist")
        let pListKey = NSDictionary(contentsOfFile: pListPath!)
        let KEY = pListKey!["APIKEY"]! as! String
        return KEY
    }
    
    // MARK: - Get Train Direction
    
    func getTrainDirection() {

        let origin = NSUserDefaults.standardUserDefaults().objectForKey("origin") as! String? ?? "WOAK"
        let destination = NSUserDefaults.standardUserDefaults().objectForKey("destination") as! String? ?? "EMBR"
        let minutesToOrigin = NSUserDefaults.standardUserDefaults().objectForKey("minutesToOrigin") as! Int? ?? 5
        let minutesToDestination = NSUserDefaults.standardUserDefaults().objectForKey("minutesToDestination") as! Int? ?? 5
        
        print("START getTrainDirection: ")
        print(origin)
        print(destination)
        print(minutesToOrigin)
        print(minutesToDestination)
        
        let BASE_URL = "http://api.bart.gov/api/sched.aspx"
        let CMD = "depart"
        let ORIG = origin
        let DEST = destination
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
                    self.buildTrainsList(trainDirections, origin: origin)
                }
            })
        }
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }
    
    // MARK: - Build Trains List
    
    func buildTrainsList(trainDirections: [String], origin: String) {
        
        let BASE_URL = "http://api.bart.gov/api/etd.aspx"
        let CMD = "etd"
        let ORIG = origin
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
                    
                    // show alert if trainsList returns empty array
                    if trainsList.count == 0 {
                        self.showAlertForNoTrains()
                    }
                    

                } // if let api call
            }) //NSOperationQueue.mainQueue

        } // session.dataTaskWithRequest
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }
    
    func getServiceAdvisory() {
        
        let BASE_URL = "http://api.bart.gov/api/bsa.aspx"
        let KEY = getApiKey()
        
        /* 2 - API method arguments */
        let methodArguments = [
            "cmd": "bsa",
            "date": "today",

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
//                    println(xml["root"]["time"])
                    //                    <time>16:53:00 PM PDT</time>
//                    println(xml["root"]["bsa"]["description"])
//                    <description>There is a major delay system wide due to a earlier medical emergency at Embarcadero Station.    Embarcadero Station is expected to be re-opened by 5pm.  </description>
//                    println(xml["root"]["bsa"]["posted"])
//                    <posted>Mon Aug 24 2015 04:35 PM PDT</posted>
//                    println(xml["root"]["bsa"]["expires"])
//                    <expires>Thu Dec 31 2037 11:59 PM PST</expires>

                    let bsaDescription = String(stringInterpolationSegment: xml["root"]["bsa"]["description"])
                    let bsaTime = String(stringInterpolationSegment: xml["root"]["bsa"]["posted"])
                    let bsaMessage = bsaTime + bsaDescription
                    let alertController = UIAlertController(title: "bsa", message: bsaMessage, preferredStyle: .Alert)
                    let defaultAction = UIAlertAction(title: "oh drat!", style: .Default, handler: nil)
                    alertController.addAction(defaultAction)
                    self.presentViewController(alertController, animated: true, completion: nil)
                    
//                    <root>
//                    <uri>http://api.bart.gov/api/bsa.aspx?cmd=bsa&date=today</uri>
//                    <date>08/24/2015</date>
//                    <time>16:43:00 PM PDT</time>
//                    <bsa id="135286">
//                    <station>BART</station>
//                    <type>DELAY</type>
//                    <description>There is a major delay system wide due to a earlier medical emergency at Embarcadero Station.    Embarcadero Station is expected to be re-opened by 5pm.  </description>
//                    <sms_text>Major delay system wide due to a earlier medical emergency at EMBR stn.    EMBR stn is expected to be re-opened by 5pm.</sms_text>
//                    <posted>Mon Aug 24 2015 04:35 PM PDT</posted>
//                    <expires>Thu Dec 31 2037 11:59 PM PST</expires>
//                    </bsa>
//                    <message/>
//                    </root>

                    
                } // if let api call
            }) //NSOperationQueue.mainQueue
            
        } // session.dataTaskWithRequest
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }

    func showAlertForNoTrains() {
        let alertController = UIAlertController(title: "No Trains", message: "I think the BART trains are asleep now", preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "Got It!", style: .Default, handler: nil)
        alertController.addAction(defaultAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    /* Helper function: convert hex to UIColor */
    func UIColorFromHex(rgbValue : UInt32, alpha : Double = 1.0) -> UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
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

