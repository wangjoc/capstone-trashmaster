//
//  MapKitViewController.swift
//  TrashMaster2
//
//  Created by Jocelyn Wang on 7/14/20.
//  Copyright © 2020 Jocelyn Wang. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase

// https://www.youtube.com/watch?v=vUvf_dlr6IU (covers user location, directions)

class MapKitViewController: UIViewController {
    
    @IBOutlet weak var mapKitView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 1000
    var previousLocation: CLLocation?
    
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    var postData = [Dictionary<String, Any>]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        checkLocationServices()
        loadData()
        
        print("MapKit has loaded")
       }
    
    func loadData() {
        ref?.child("trashcan").observe(.childAdded, with: { (snapshot) in
            let data = (snapshot.value as? NSDictionary)
            
            let title = (snapshot.value as? NSDictionary)?["title"] as? String ?? ""
            let latitude = (snapshot.value as? NSDictionary)?["latitude"] as? Double ?? 0
            let longitude = (snapshot.value as? NSDictionary)?["longitude"] as? Double ?? 0
            
            self.postData.append(["title": title, "latitude": latitude, "longitude": longitude])
            
            self.createAnnotations(locations: self.postData)
        })
    }
    
    func addTrashCanData () {
        let destinationCoordinate = getCenterLocation(for: mapKitView).coordinate
        ref?.child("trashcan").childByAutoId().setValue(["title":"Trash Can", "latitude": Double(round(1000000 * destinationCoordinate.latitude)/1000000), "longitude": Double(round(1000000 * destinationCoordinate.longitude)/1000000)])
    }
    
    // annotating locations on map: https://www.youtube.com/watch?v=D9pFZsRdynw
    func createAnnotations(locations: [[String: Any]]) {
        for location in locations {
            let annotations = MKPointAnnotation()
            annotations.title = location["title"] as? String
            annotations.coordinate = CLLocationCoordinate2D(latitude: location["latitude"] as! CLLocationDegrees, longitude: location["longitude"] as! CLLocationDegrees)
            
            mapKitView.addAnnotation(annotations)
        }
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapKitView.setRegion(region, animated: true)
        }
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            // Show alert letting the user know they have to turn this on
        }
    }
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            startTrackingUserLocation()
        case .denied:
            // show alert instructing them how to turn on permissions
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            // show alert letting them know that permission is restricted
            break
        case .authorizedAlways:
            break
        }
    }
    
    func startTrackingUserLocation() {
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapKitView)
    }
    
    func getCenterLocation(for mapKitView: MKMapView) -> CLLocation {
        let latitude = mapKitView.centerCoordinate.latitude
        let longitude = mapKitView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func getDirections() {
        guard let location = locationManager.location?.coordinate else {
            //TODO: Inform user we don't have their current location
            return
        }
        
        let request = createDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
        
        directions.calculate { [unowned self] (response, error) in
            //TODO: Handle error if needed
            guard let response = response else { return } //TODO: Show response not available in an alert
            
            for route in response.routes {
                self.mapKitView.addOverlay(route.polyline)
                self.mapKitView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate = getCenterLocation(for: mapKitView).coordinate
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .walking
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    @IBAction func goButtonTapped(_ sender: UIButton) {
        getDirections()
    }
    
    
    @IBAction func mapToDash(_ sender: UIButton) {
        print("Go to Dashboard")
        self.performSegue(withIdentifier: "MapToDashSegue", sender: self)
    }
    
    @IBAction func returnToUserLocation(_ sender: UIButton) {
        centerViewOnUserLocation()
    }
    
    @IBAction func addTrashCan(_ sender: UIButton) {
        addTrashCanData()
    }
}

extension MapKitViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}

extension MapKitViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapKitView)
        let geoCoder = CLGeocoder()
        
        guard let previousLocation = self.previousLocation else { return }
        
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        geoCoder.reverseGeocodeLocation(center) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            if let _ = error {
                //TODO: Show alert informing the user
                return
            }
            
            guard let placemark = placemarks?.first else {
                //TODO: Show alert informing the user
                return
            }
            
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async {
               self.addressLabel.text = "\(streetNumber) \(streetName)"
            }
            
            print("\(streetNumber) \(streetName)")
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .green
        
        return renderer
    }
}
