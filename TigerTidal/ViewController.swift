//
//  ViewController.swift
//  TigerTidal
//
//  Created by Sam Jordan on 11/1/14.
//  Copyright (c) 2014 Sam Jordan. All rights reserved.
//

import UIKit
import Foundation
import Darwin

class ViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var settingsBtn: UIButton!

    //booleans for tracking state combinations
    var userConfirmedLocAuth: Bool! = false
    var haveUserPref:Bool! = false
    var firstRun:Bool! = true
    var inBounds:Bool! = false
    
    
    
    //constants:
    let updateDLDataRate:Double = 15 //seconds
    let updateULDataRate:Double = 7 //seconds
    let updateDrawRate:Double = 0.25 //seconds
    let clearDataRate:Double = 60 //seconds
    
    let locationManager = CLLocationManager()
    let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
    let dataURL: String = "https://tigertidal.herokuapp.com/db"
    var myFirstName  = ""
    var myLastName = ""
    var myClassYear = ""
    var myUid = ""
    var anon = false
    
    
    //global vars:
    var activeUserDict = [String:ActiveUser]()
    var activeMarkerDict = [String:GMSMarker]()
    var latMin = 40.336703 //min and max boundaries, past edge of campus:
    var latMax = 40.351684
    var longMin = -74.675656
    var longMax = -74.629093
    var myLong:Double = 40.348812 //default to nassau hall
    var myLat:Double = -74.659387 //default to nassau hall
    var myHeading:Double = 0.0
    var mySpeed:Double = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //build settings button
        settingsBtn = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        settingsBtn.frame = CGRectMake(45, 45, 45, 45)
        settingsBtn.setImage(UIImage(named: "settings 12"), forState: .Normal)
        settingsBtn.setTitle("Settings", forState: .Normal)
        settingsBtn.addTarget(self, action: "settingsAct:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.insertSubview(self.settingsBtn, aboveSubview: self.mapView)
        
        //set up location manager
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.requestWhenInUseAuthorization()
        
        //load saved data, trigger settings page if nil:
        if let cy = defaults.objectForKey("classYear") as? String {
            //there is some saved data
            haveUserPref = true
            if let firstNameIsNotNill = defaults.objectForKey("firstName") as? String {
                myFirstName = firstNameIsNotNill
            }
            if let lastNameIsNotNill = defaults.objectForKey("lastName") as? String {
                myLastName = lastNameIsNotNill
            }
            if let classYearIsNotNill = defaults.objectForKey("classYear") as? String {
                myClassYear = classYearIsNotNill
            }
            if let anonSwitchIsNotNill = defaults.objectForKey("anon") as? Bool {
                anon = anonSwitchIsNotNill
            }
        } else {
            haveUserPref = false
        }
        
        myUid = String(UIDevice.currentDevice().identifierForVendor.UUIDString.hashValue)
        
        //start getting initial data
        updateUL()
        updateDL()
        
        
        //set up mapview and camera
        var target: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 40.348828, longitude: -74.659413)
        var camera: GMSCameraPosition = GMSCameraPosition(target: target, zoom: 18, bearing: 0, viewingAngle: 18)
        mapView.camera = camera
        mapView.delegate = self
        mapView.settings.compassButton = true; //does this do anything?
        
        
        //update local data loop
        var dlDataTimer = NSTimer.scheduledTimerWithTimeInterval(updateDLDataRate, target: self, selector: Selector("updateDL"), userInfo: nil, repeats: true)
        //update screen loop
        var drawTimer = NSTimer.scheduledTimerWithTimeInterval(updateDrawRate, target: self, selector: Selector("updateDraw"), userInfo: nil, repeats: true)
        //update server data loop
        var ulDataTimer = NSTimer.scheduledTimerWithTimeInterval(updateULDataRate, target: self, selector: Selector("updateUL"), userInfo: nil, repeats: true)
        //clear out old data loop
        var clearDataTimer = NSTimer.scheduledTimerWithTimeInterval(clearDataRate, target: self, selector: Selector("clearData"), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //hide the navbar, load in user prefs
    override func viewWillAppear(animated: Bool) {
        if (defaults.objectForKey("classYear") == nil) {
            if (userConfirmedLocAuth == true){
                toast("Please tap on the gear icon in the top left", title: "Settings Required!", btntext: "Ok")
            }
            else if (!firstRun) {
                toast("Go and enable location services for this app in Settings.", title: "Location Required!", btntext: "Ok")
            }
        }
        else {
            haveUserPref = true
        }
        if (!firstRun && !userConfirmedLocAuth) {
            toast("Go and enable location services for this app in Settings.", title: "Location Required!", btntext: "Ok")
        }
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        println("reloading settings...")
        //reload names in case they changed:
        if let anonSwitchIsNotNill = defaults.objectForKey("anon") as? Bool {
            anon = anonSwitchIsNotNill
        }
        if (anon == true) { //make anonymous if necesary
            myFirstName = "anon"
        }
        else if let firstNameIsNotNill = defaults.objectForKey("firstName") as? String {
            myFirstName = firstNameIsNotNill
        }
        if (anon == true) {
            myLastName = "user"
        }
        else if let lastNameIsNotNill = defaults.objectForKey("lastName") as? String {
            myLastName = lastNameIsNotNill
        }
        
        if let classYearIsNotNill = defaults.objectForKey("classYear") as? String {
            myClassYear = classYearIsNotNill
        }
        
        if (!firstRun) {
            updateDL()
        }
        super.viewWillAppear(animated)
    }
    
    //show the navbar
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        firstRun = false
        
        clearData()
        super.viewWillDisappear(animated)
    }


    //'go to settings' action
    @IBAction func settingsAct (sender: UIButton!) {
        performSegueWithIdentifier("SettingsSegue", sender: self)

    }
    
    func clearData() {
        //reset map, dictionaries so old members won't be there forever
        println("clearing map and dicts...")
        mapView.clear()
        activeUserDict.removeAll(keepCapacity: true)
        activeMarkerDict.removeAll(keepCapacity: true)
    }

    
    func updateDL() {
        if (!userConfirmedLocAuth || !haveUserPref || !inBounds) {
            //don't give other peoples data until location is being shared
            println("no locAuth, no pref, or not in bounds; not updating data...")
            return
        }
        println("updating data...");
        getJsonData(dataURL)
    }
    
    func updateUL() {
        if (!userConfirmedLocAuth || !haveUserPref || !inBounds) {
            //don't try to send data until confirmation
            println("no locAuth, no pref, or not in bounds; not uploading location...")
            if let locnotnil = locationManager.location {
                //loc is not null, so just return
                return
            }
            else {
                println("attempted POST Error!")
                println("location is nil")
                toast("TigerTidal cannot access your location, please enable location services for this app.", title: "Location Error!", btntext: "Ok")
                return
            }
        }
        println("POSTing loc to server...")
        
        if let location = locationManager.location {
            var updateDict: Dictionary<String, String> = ["firstname":myFirstName, "lastname":myLastName, "uid":myUid, "classyear":myClassYear, "longitude":self.locationManager.location.coordinate.longitude.description, "latitude":self.locationManager.location.coordinate.latitude.description, "heading":self.locationManager.location.course.description, "speed":self.locationManager.location.speed.description]
            post(updateDict, url: dataURL)
        }
        else {
            println("attempted POST Error!")
            println("location is nil")
            toast("TigerTidal cannot access your location, please enable location services for this app.", title: "Location Error!", btntext: "Ok")
        }
    }
    
    func updateDraw() {
        for (key, marker) in activeMarkerDict {
            var activeUser = activeUserDict[key]!
            
            //calculate new position based on velocity
            activeUser.updateLoc(updateDrawRate)
            
            //update marker to new position
            marker.position = CLLocationCoordinate2DMake(activeUser.latitude, activeUser.longitude)
        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            println("user athorized location tracking")
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            
            //show location on map
            mapView.myLocationEnabled = true
            mapView.settings.myLocationButton = true
            userConfirmedLocAuth = true
            
            //go to appropriate action, settings or start fetching data...
            if (haveUserPref == true) {
                updateDL()
            } else {
                settingsAct(settingsBtn)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let location = locations.first as? CLLocation {
            var loc: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            userConfirmedLocAuth = true
            
            // check if user is in bounds, if not display message:
            if (loc.latitude > latMax || loc.latitude < latMin || loc.longitude > longMax || loc.longitude < longMin) {
                toast("This app is meant to be used on the Princeton campus. Please return to campus to use this app.", title: "Out of bounds!", btntext: "Ok")
                inBounds = false
            }
            else {
                inBounds = true
            }
        }
    }
    
    //function to send messages to user
    func toast(message:String, title:String, btntext:String) {
        println("toasting '\(message)'")
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: btntext, style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //POST function, sends json data to URL
    func post(params : Dictionary<String, String>, url : String) {
        var request = NSMutableURLRequest(URL: NSURL(string: url)!)
        var session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        var err: NSError?
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        if((err) != nil) {
            println(err!.localizedDescription)
        }
        else {
            var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                if let httpResponse = response as? NSHTTPURLResponse {
                    if (httpResponse.statusCode == 200) {
                        println("POST response OK")
                    }
                    else {
                        println("POST Error!")
                        println("response status:\(httpResponse.statusCode)")
                    }
                }
                else {
                    //no response from server!
                    println("POST Error!")
                    println("no response from server")
                    self.toast("Could not connect to server",title:"Connection Error!",btntext:"Ok")
                }
            })
            task.resume()
        }
    }
    
    //GET function, gets JSON data from url
    func getJsonData(urlPath: String) {
        var url: NSURL = NSURL(string: urlPath)!
        var request1: NSURLRequest = NSURLRequest(URL: url)
        let queue:NSOperationQueue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request1, queue: queue, completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            if (error != nil) {
                println("Async D/L Error!")
                println(error)
                dispatch_async(dispatch_get_main_queue(), {
                    self.toast("Could not connect to server",title:"Connection Error!",btntext:"Ok")
                })
                return
            }
            
            var jsonError: NSError?
            if let json: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &jsonError) as? [String : AnyObject] {
                // this code is executed if the json is a NSDictionary
                if (json != nil) {
                    println("JSON loaded successfully")
                    
                    if let activeUsers = json["activeUsers"]! as? [[String : AnyObject]] {
                        // safe to use activeUsers
                        for user in activeUsers {
                            
                            //check for bad data:
                            if (user["firstname"] == nil
                                || user["lastname"] == nil
                                || user["classyear"] == nil
                                ||  user["uid"] == nil) {
                                    //(have to split them up or xcode complains)
                                    if (user["latitude"] == nil
                                        || user["longitude"] == nil
                                        || user["heading"] == nil
                                        || user["speed"] == nil) {
                                            println("D/L JSON Error!")
                                            println("A required field is null")
                                            
                                            // toast saying malformed data from server
                                            // use main thread
                                            dispatch_async(dispatch_get_main_queue(), {
                                                self.toast("Server returned bad data",title:"Server Error!",btntext:"Ok")
                                            })
                                            return;
                                    }
                            }
                            
                            //all is OK so far, get data from JSON dict:
                            var firstName = user["firstname"]! as String
                            var lastName = user["lastname"]! as String
                            var UID = user["uid"]! as String
                            var classYear = user["classyear"]! as String
                            var lat = user["latitude"]!.doubleValue
                            var long = user["longitude"]!.doubleValue
                            var heading = user["heading"]!.doubleValue
                            var speed = user["speed"]!.doubleValue
                            
                            //don't add user if its me!
                            if (UID == self.myUid) {
                                continue
                            }

                            //default speed and heading if they appear invalid:
                            if (heading < 0) {
                                heading = 0.0
                            }
                            if (speed < 0) {
                                speed = 0.0
                            }
                            
                            //if user is out of bounds, ignore his data:
                            if (lat < self.latMin || lat > self.latMax || long < self.longMin || long > self.longMax) {
                                //user is now out of bounds, don't show position
                                println("\(firstName) \(lastName) is out of bounds! skipping...")
                                continue
                            }
                            
                            
                            //now execute with main thread, so GMS calls won't fail
                            dispatch_async(dispatch_get_main_queue(), {
                                //update activeUser dict
                                if let curUser = self.activeUserDict[UID] {
                                    //user and marker already in dict, just update fields:
                                    curUser.latitude = lat
                                    curUser.longitude = long
                                    curUser.heading = heading
                                    curUser.speed = speed
                                    let marker = self.activeMarkerDict[UID]!
                                    marker.position = CLLocationCoordinate2DMake(lat, long)
                                    marker.rotation = heading
                                } else {
                                    //user and marker not in dict, create:
                                    var activeUser = ActiveUser()
                                    activeUser.createUser(firstName, lastName: lastName, uid: UID, classYear: classYear,  latitude: lat, longitude: long, heading:heading, speed:speed)
                                    let marker = GMSMarker()
                                    marker.position = CLLocationCoordinate2DMake(activeUser.latitude, activeUser.longitude)
                                    marker.title = activeUser.displayName()
                                    marker.snippet = activeUser.classYear
                                    marker.icon = UIImage(named: "my_arrow")
                                    marker.flat = true;
                                    marker.rotation = activeUser.heading
                                    marker.map = self.mapView
                                    self.activeUserDict.updateValue(activeUser, forKey: activeUser.uid)
                                    self.activeMarkerDict.updateValue(marker, forKey: activeUser.uid)
                                    println("added: \(activeUser.displayName())")
                                    //activeUser.printUser()
                                }
                            })
                        }
                    }
                } else {
                    println("json is nil")
                    //toast saying server did not respond with data
                    println("D/L Error!")
                    println("empty response from server")
                    dispatch_async(dispatch_get_main_queue(), {
                        self.toast("Recieved empty response from server",title:"No Data!",btntext:"Ok")
                    })
                }
            } else {
                // JSON unwrap error, log to console:
                if let unwrappedError = jsonError {
                    println("D/L JSON Error!")
                    println("json error: \(unwrappedError)")
                }
            }
        })
    }
    
    
    
    //activeUser class: struct and functions
    class ActiveUser {
        var firstName: String = ""
        var lastName: String = ""
        var uid:String = ""
        var classYear: String = ""
        var latitude: Double = 0.0
        var longitude: Double = 0.0
        var heading: Double = 0.0
        var speed: Double = 0.0
        var anon:Bool = false
        
        func createUser(firstName:String, lastName:String, uid:String,
            classYear:String, latitude:Double, longitude:Double, heading:Double, speed:Double) {
            self.firstName = firstName
            if (firstName == "anon") {
                self.anon = true
            }
            self.lastName = lastName
            self.uid = uid
            self.latitude = latitude
            self.longitude = longitude
            self.classYear = classYear
            self.heading = heading
            self.speed = speed
        }
        
        func displayName() -> String{
            if (anon == true) {
                return "Anonymous User"
            }
            else {
                return firstName + " " + lastName
            }
        }
        
        func updateLoc(time: Double) {
            if (speed < 0.1) {
                return //if they're going that slowly, don't interpolate movement
            }
            var totDist = speed*time
            latitude += metToLat(totDist * cos(degToRad(heading)))
            longitude += metToLong(totDist * sin(degToRad(heading)))
        }
        
        func degToRad(degrees: Double) ->Double {
            return (degrees * M_PI/180)
        }
        
        //returns number of latitude degrees changed from meters travelled (approx)
        func metToLat(meters: Double) ->Double {
            //return (meters/84395.01114552133)
            return (meters/111041.3151719585)
        }
        
        //returns number of longitude degrees changed from meters travelled (approx)
        func metToLong(meters: Double) ->Double {
            //return (meters/111122.19769899677)
            return (meters/84957.75707320592)
        }
        
        //print func, for debugging
        func printUser() {
            println("firstName:\(firstName)")
            println("lastName:\(lastName)")
            println("uid: \(uid)")
            println("classYear:\(classYear)")
            println("lat:\(latitude)")
            println("long:\(longitude)")
            println("heading:\(heading)")
            println("speed:\(speed)")
        }
        
    }
}

