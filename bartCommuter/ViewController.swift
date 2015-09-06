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
    
    var stations = [
        "12th": "12th St. / Oakland City Center",
        "16th": "16th St. Mission",
        "19th": "19th St. Oakland",
        "24th": "24th St. Mission",
        "ashb": "Ashby",
        "balb": "Balboa Park",
        "bayf": "Bay Fair",
        "cast": "Castro Valley",
        "civc": "Civic Center",
        "cols": "Coliseum / Oakland Airport",
        "colm": "Colma",
        "conc": "Concord",
        "daly": "Daly City",
        "dbrk": "Downtown Berkeley",
        "dubl": "Dublin / Pleasanton",
        "deln": "El Cerrito del Norte",
        "plza": "El Cerrito Plaza",
        "embr": "Embarcadero",
        "frmt": "Fremont",
        "ftvl": "Fruitvale",
        "glen": "Glen Park",
        "hayw": "Hayward",
        "lafy": "Lafayette",
        "lake": "Lake Merritt",
        "mcar": "MacArthur",
        "mlbr": "Millbrae",
        "mont": "Montgomery",
        "nbrk": "North Berkeley",
        "ncon": "North Concord / Martinez",
        "orin": "Orinda",
        "pitt": "Pittsburg / Bay Point",
        "phil": "Pleasant Hill",
        "powl": "Powell",
        "rich": "Richmond",
        "rock": "Rockridge",
        "sbrn": "San Bruno",
        "sanl": "San Leandro",
        "sfia": "SFO Airport",
        "shay": "South Hayward",
        "ssan": "South San Francisco",
        "ucty": "Union City",
        "wcrk": "Walnut Creek",
        "wdub": "West Dublin / Pleasanton",
        "woak": "West Oakland",
        "spcl": "Special"
    ]
        
    struct Train {
        var destination: String = ""
        var destinationCode: String = ""
        var hexColor: String  = ""
        var minutes: Int = -1
        var length: String = ""
    }
    
    var sortedTrainList : [Train] = []
    var currentTrainIndex : Int = 0
    var currentTravelTime : Int = 0
    
    let hour : Int = {
        /* Get current hour */
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.CalendarUnitHour | .CalendarUnitMinute, fromDate: date)
        let hour = components.hour
        return hour
    }()
    
    var timer : NSTimer!
    
    
    // MARK: - Main Running Loop
    
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
    
    // MARK: - Table Views
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let origin = NSUserDefaults.standardUserDefaults().objectForKey("origin") as! String
        let destination = NSUserDefaults.standardUserDefaults().objectForKey("destination") as! String
        let etdIndicatorColors : [UInt32] = [0xe51c23, 0xff9800, 0x259b24, 0x009688, 0x00BCD4, 0x03a9f4, 0x5677fc, 0x3f51b5]
        
        if indexPath.row == currentTrainIndex {
            let cell : ChosenTrainTableCell = tableView.dequeueReusableCellWithIdentifier("chosenTrain", forIndexPath: indexPath) as! ChosenTrainTableCell
            println("train coming in: \(sortedTrainList[indexPath.row].minutes) - timeToStation: \(self.currentTravelTime) \(sortedTrainList[indexPath.row].minutes - self.currentTravelTime)")
            cell.chosenDirection.text = "\(self.stations[origin]!) to \(stations[destination]!)"
            cell.chosenTrainInfo.text = "\(sortedTrainList[indexPath.row].length) Cars - \(sortedTrainList[indexPath.row].destination)"
            var etdColorTime = sortedTrainList[indexPath.row].minutes - self.currentTravelTime
            if etdColorTime > 6 { etdColorTime = 7 } // catch out of range values
            if etdColorTime >= 0 {
                cell.backgroundColor = UIColor.UIColorFromHex(etdIndicatorColors[etdColorTime])
                cell.chosenTrainLabel?.text = "\(sortedTrainList[indexPath.row].minutes)"
            }
            return cell
        } else {
            let cell : TrainTableCell = tableView.dequeueReusableCellWithIdentifier("train", forIndexPath: indexPath) as! TrainTableCell
            cell.backgroundColor = UIColor.UIColorFromHex(0xCCCCCC)
            
            cell.individualTrainLabel?.text = "\(sortedTrainList[indexPath.row].minutes) min - \(sortedTrainList[indexPath.row].length) cars - \(sortedTrainList[indexPath.row].destination)"
            //            cell.textLabel?.textColor = UIColorFromHex(etdIndicatorColors[indexPath.row + 1])
            return cell
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedTrainList.count
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row != currentTrainIndex {
            return 40
        } else {
            return 375
        }
    }
    
    // MARK: - Get Current Train Index

    func getCurrentTrainIndex(sortedTrainList: [Train]) -> Int? {
        let minutesToOrigin = NSUserDefaults.standardUserDefaults().objectForKey("minutesToOrigin") as! Int? ?? 0
        for (index, train) in enumerate(sortedTrainList) {
            println("current train index\(index) -  trainMinutes \(train.minutes)")
            if train.minutes >= minutesToOrigin {
                return index
            }
        }
        return nil
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

        let origin = NSUserDefaults.standardUserDefaults().objectForKey("origin") as! String
        let destination = NSUserDefaults.standardUserDefaults().objectForKey("destination") as! String
        let minutesToOrigin = NSUserDefaults.standardUserDefaults().objectForKey("minutesToOrigin") as! Int
        
        print("getTrainDirection: \(origin)/\(destination) - \(minutesToOrigin)/ - ")
        
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
                            var trainHead = trip["leg"][0].element!.attributes["trainHeadStation"]!
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

                    // show alert if trainsList returns empty array
                    if trainsList.count == 0 {
                        self.timer.invalidate()
                        self.showAlertForNoTrains()
                    } else {
                    
                        trainsList.sort({ $0.minutes < $1.minutes })
                        self.sortedTrainList = trainsList
                        self.currentTrainIndex = self.getCurrentTrainIndex(trainsList) ?? 0
                        self.currentTravelTime = NSUserDefaults.standardUserDefaults().objectForKey("minutesToOrigin") as! Int
                        self.trainTableView.reloadData()
                        
                        for train in trainsList {
                            println("Train: \(train.minutes) \(train.destination) \(train.destinationCode) \(train.length) \(train.hexColor) \(self.currentTrainIndex)")
                        }
                    }

                    

                } // if let api call
            }) //NSOperationQueue.mainQueue

        } // session.dataTaskWithRequest
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }
    
    // MARK: - Get Service Advisory

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

                    let bsaDelay =  xml["root"]["bsa"]["delay"].element?.text
                    println("bsaDelay: \(bsaDelay)")
                    println(xml)
                    let bsaDescription =  xml["root"]["bsa"]["description"].element!.text
                    let bsaTime = xml["root"]["bsa"]["posted"].element?.text ?? ""
                    let bsaMessage = bsaDescription! + "\n\n" + bsaTime
                    let alertController = UIAlertController(title: "BART Service Advisory", message: bsaMessage, preferredStyle: .Alert)
                    let defaultAction = UIAlertAction(title: "ok", style: .Default, handler: nil)
                    alertController.addAction(defaultAction)
                    
                    // if advisory includes default text, don't pop an alert.
                    let noDelays = "No delays"
                    print("bsa: \(bsaDescription!) rangeOfString: ")
                    println(bsaDescription!.rangeOfString(noDelays))
                    if bsaDescription!.rangeOfString(noDelays) == nil {
                        self.presentViewController(alertController, animated: true, completion: nil)
                    }
                } // if let api call
            }) //NSOperationQueue.mainQueue
            
        } // session.dataTaskWithRequest
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }
    
    @IBAction func refresh(sender: UIBarButtonItem) {
        getServiceAdvisory()
        getTrainDirection()
    }
    
    @IBAction func reverseDirection(sender: UIBarButtonItem) {
        let origin = NSUserDefaults.standardUserDefaults().objectForKey("origin") as! String
        let destination = NSUserDefaults.standardUserDefaults().objectForKey("destination") as! String
        let minutesToOrigin = NSUserDefaults.standardUserDefaults().objectForKey("minutesToOrigin") as! Int
        let minutesToDestination = NSUserDefaults.standardUserDefaults().objectForKey("minutesToDestination") as! Int

        NSUserDefaults.standardUserDefaults().setObject(origin, forKey: "destination")
        NSUserDefaults.standardUserDefaults().setObject(destination, forKey: "origin")
        NSUserDefaults.standardUserDefaults().setObject(minutesToOrigin, forKey: "minutesToDestination")
        NSUserDefaults.standardUserDefaults().setObject(minutesToDestination, forKey: "minutesToOrigin")

        getServiceAdvisory()
        getTrainDirection()
    }
    

    func showAlertForNoTrains() {
        let alertController = UIAlertController(title: "No Trains", message: "I think the BART trains are asleep now", preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "Got It!", style: .Default, handler: nil)
        alertController.addAction(defaultAction)
        self.presentViewController(alertController, animated: true, completion: nil)
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

