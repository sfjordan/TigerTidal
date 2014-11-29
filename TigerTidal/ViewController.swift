//
//  ViewController.swift
//  TigerTidal
//
//  Created by Sam Jordan on 11/1/14.
//  Copyright (c) 2014 Sam Jordan. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var mapView: GMSMapView!
    
    var firstLocationUpdate: Bool?
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        let marker = GMSMarker()
//        marker.position = CLLocationCoordinate2DMake(-33.86, 151.20)
//        marker.title = "Sydney"
//        marker.snippet = "Australia"
//        marker.map = mapView

        
        locationManager.delegate = self
//        locationManager.distanceFilter = kCLDistanceFilterNone;
        
        let urlPath: String = "https://eerie-ghoul-2405.herokuapp.com/db"
        getJsonData(urlPath)
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.requestWhenInUseAuthorization()
        var target: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 40.348828, longitude: -74.659413)
        var camera: GMSCameraPosition = GMSCameraPosition(target: target, zoom: 18, bearing: 0, viewingAngle: 18)
        
        println("LOAD mapview is nil: \(mapView == nil)")
        println("LOAD mapView.myLocation: \(mapView.myLocation)")
        
        mapView.camera = camera
        mapView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 1
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        // 2
        if status == .AuthorizedWhenInUse {
            
            // 3
            locationManager.startUpdatingLocation()
            
            println("CHAUTH mylocation: \(mapView.myLocation)")
            
            mapView.myLocationEnabled = true
            mapView.settings.myLocationButton = true
            
        }
    }
    
    // 5
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let location = locations.first as? CLLocation {
            
            println("CHLOC: \(mapView.myLocation)")
            // 6
            var locTarget: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            //mapView.camera = GMSCameraPosition(target: locTarget, zoom: 18, bearing: 0, viewingAngle: 18)
            return;
            
        }
    }
    
    func getJsonData(urlPath: String) {
        var url: NSURL = NSURL(string: urlPath)!
        var request1: NSURLRequest = NSURLRequest(URL: url)
        let queue:NSOperationQueue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request1, queue: queue, completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            /* Your code */
//            if (error != nil) {
//                println("error:")
//                println(error)
//            }
            
            var jsonError: NSError?
            if let json: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &jsonError) as? [String : AnyObject] {
                // this code is executed if the json is a NSDictionary
                if (json != nil) {
                    println("JSON: \(json)")
                    if let activeUsers = json["activeUsers"]! as? [[String : AnyObject]] {
                        // safe to use activeUsers
                        for user in activeUsers {
                            let firstName = user["firstname"]! as String
                            let lastName = user["lastname"]! as String
                        
                            println("user: \(firstName) \(lastName)")
                        }
                    }
                } else {
                    println("json is nil")
                }
            } else {
                // otherwise, this code is executed
                if let unwrappedError = jsonError {
                    println("json error: \(unwrappedError)")
                }
            }
            
            
        })
    }



}

