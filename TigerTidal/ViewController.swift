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
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.requestWhenInUseAuthorization()
        var target: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 40.348828, longitude: -74.659413)
        var camera: GMSCameraPosition = GMSCameraPosition(target: target, zoom: 18, bearing: 0, viewingAngle: 15)
        
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
            
            println("CHAUTH: \(mapView.myLocation)")
            
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
            mapView.camera = GMSCameraPosition(target: locTarget, zoom: 18, bearing: 0, viewingAngle: 18)
            return;
            
        }
    }


}

