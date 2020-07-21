//
//  ReportTrashController.swift
//  TrashMaster2
//
//  Created by Jocelyn Wang on 7/15/20.
//  Copyright © 2020 Jocelyn Wang. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase

// https://www.youtube.com/watch?v=vUvf_dlr6IU (covers user location, directions)

class ReportTrashController: UIViewController {
    
    @IBOutlet weak var ReportMapView: MKMapView!
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
        
           print("Trash Reporter has loaded")
       }
    
    func loadData() {
        print("Start load data")
        ref?.child("trash-location").observe(.childAdded, with: { (snapshot) in
            let data = (snapshot.value as? NSDictionary)
            
            let title = (snapshot.value as? NSDictionary)?["title"] as? String ?? ""
            let latitude = (snapshot.value as? NSDictionary)?["latitude"] as? Double ?? 0
            let longitude = (snapshot.value as? NSDictionary)?["longitude"] as? Double ?? 0
            
            self.postData.append(["title": title, "latitude": latitude, "longitude": longitude])
            print(self.postData)
            self.createAnnotations(locations: self.postData)
        })
    }
    
    func createAnnotations(locations: [[String: Any]]) {
        for location in locations {
            let annotations = MKPointAnnotation()
            annotations.title = location["title"] as? String
            annotations.coordinate = CLLocationCoordinate2D(latitude: location["latitude"] as! CLLocationDegrees, longitude: location["longitude"] as! CLLocationDegrees)
            
            ReportMapView.addAnnotation(annotations)
        }
    }
    
    func markLocation() {
        let destinationCoordinate = getCenterLocation(for: ReportMapView).coordinate
        ref?.child("trash-location").childByAutoId().setValue(["title":"Trash", "latitude": Double(round(1000000 * destinationCoordinate.latitude)/1000000), "longitude": Double(round(1000000 * destinationCoordinate.longitude)/1000000)])
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)

            ReportMapView.setRegion(region, animated: true)
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
        previousLocation = getCenterLocation(for: ReportMapView)
    }
    
    func getCenterLocation(for ReportMapView: MKMapView) -> CLLocation {
        let latitude = ReportMapView.centerCoordinate.latitude
        let longitude = ReportMapView.centerCoordinate.longitude
        
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
                self.ReportMapView.addOverlay(route.polyline)
                self.ReportMapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate = getCenterLocation(for: ReportMapView).coordinate
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
    
    
    @IBAction func goToDash(_ sender: Any) {
        print("Go to Dashboard")
        self.performSegue(withIdentifier: "MapReportToDashSegue", sender: self)
    }
    
    @IBAction func markTrash(_ sender: UIButton) {
        markLocation()
    }
    
    
    @IBAction func returnToUserLocation(_ sender: UIButton) {
        centerViewOnUserLocation()
    }
}

extension ReportTrashController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}

extension ReportTrashController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: ReportMapView)
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

