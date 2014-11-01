//
//  ViewController.swift
//  TigerTidal
//
//  Created by Sam Jordan on 11/1/14.
//  Copyright (c) 2014 Sam Jordan. All rights reserved.
//

import UIKit

class ViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    

    @IBOutlet weak var mapView: GMSMapView!
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        var target: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 40.348828, longitude: -74.659413)
        var camera: GMSCameraPosition = GMSCameraPosition(target: target, zoom: 18, bearing: 0, viewingAngle: 15)
        
        println("view DidLoad mapview is nil: \(mapView == nil)")
        
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
            println("Location: \(locationManager.location)")
            
            println("didChangeAuth mapview is nil: \(mapView == nil)")
            
            mapView.myLocationEnabled = true
            mapView.settings.myLocationButton = true
            
        }
    }
    
    // 5
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let location = locations.first as? CLLocation {
            
            println("didUpdateLocations mapview is nil: \(mapView == nil)")
            // 6
            mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 18, bearing: 0, viewingAngle: 15)
        }
    }


}

