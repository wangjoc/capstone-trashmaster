//
//  MapViewController.swift
//  TrashMaster2
//
//  Created by Jocelyn Wang on 7/14/20.
//  Copyright © 2020 Jocelyn Wang. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // https://www.youtube.com/watch?v=8wPjCdDn2wo
        
        GMSServices.provideAPIKey("AIzaSyA27ktD8P5nEmbXzCGhqqR_oHxO6tAqqIU")
        
        let camera = GMSCameraPosition.camera(withLatitude: 37.621262, longitude: -122.378945, zoom: 10)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        view = mapView
    }


}
