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
    @IBOutlet var AllMapView: UIView!
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 1000
    var previousLocation: CLLocation?
    
    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    var postData = [Dictionary<String, Any>]()
    var annotationData: NSDictionary?
    
    enum CardState {
        case expanded
        case collapsed
    }
    
    var reportDetailController:ReportDetailController!
    var visualEffectView:UIVisualEffectView!
    
    let cardHeight:CGFloat = 600
    let cardHandleAreaHeight:CGFloat = 65
    
    var cardVisible = false
    var nextState:CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted:CGFloat = 0
    
    override func viewDidLoad() {
       super.viewDidLoad()
       ref = Database.database().reference()
       checkLocationServices()
       loadData()
       
       print("Trash Reporter has loaded")
    }
    
    // https://www.youtube.com/watch?time_continue=655&v=uKQjJb-KSwU&feature=emb_logo
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ReportFormController {
            let destinationCoordinate = getCenterLocation(for: ReportMapView).coordinate
            
            var rfc = segue.destination as! ReportFormController
            rfc.data = ["title":"Trash", "latitude": Double(round(1000000 * destinationCoordinate.latitude)/1000000), "longitude": Double(round(1000000 * destinationCoordinate.longitude)/1000000)]
            rfc.address = self.addressLabel.text ?? "N/A"
        }
    }
    
    func getAnnotationInfo(snapshotKey: String) {
        ref?.child("trash-location").child(snapshotKey).observeSingleEvent(of: .value, with: { (snapshot) in
            let data = (snapshot.value as? NSDictionary)
            self.annotationData = data
        })
        print("Retrieved Annotation Data")
    }
        
    
    // Create card: https://www.youtube.com/watch?v=L-f1KSPKm4I
    func setupCard(annotation: MKPointAnnotation) {
        ref?.child("trash-location").child(annotation.subtitle!).observeSingleEvent(of: .value, with: { (snapshot) in
            let data = (snapshot.value as? NSDictionary)
            self.annotationData = data
            
            // https://stackoverflow.com/questions/39459555/swift-3-how-to-download-profile-image-from-firebase-storage
            let storage = Storage.storage()
            var reference: StorageReference!
            reference = storage.reference(forURL: self.annotationData?["trashImageURL"] as! String)
            reference.downloadURL { (url, error) in
                let data = NSData(contentsOf: url!)
                let image = UIImage(data: data! as Data)
                self.reportDetailController.annotationImage.image = image
            }
            
            self.reportDetailController.annotationTitle.text = self.annotationData!["title"] as! String
            self.reportDetailController.annotationDescription.text = self.annotationData!["description"] as! String
        })
        
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = self.view.frame
        self.view.addSubview(visualEffectView)
        
        reportDetailController = ReportDetailController(nibName: "ReportDetailController", bundle:nil)
        self.addChild(reportDetailController)
        self.view.addSubview(reportDetailController.view)
        
        reportDetailController.view.frame = CGRect(x: 0, y: self.view.frame.height - self.cardHandleAreaHeight, width: self.view.bounds.width, height: cardHeight)
        reportDetailController.view.clipsToBounds = false
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ReportTrashController.handleCardTap(recognizer:)))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ReportTrashController.handleCardPen(recognizer:)))
        
        reportDetailController.handleArea.addGestureRecognizer(tapGestureRecognizer)
        reportDetailController.handleArea.addGestureRecognizer(panGestureRecognizer)
        
        animateTransitionIfNeeded(state: nextState, duration: 0.9)
    }
    
    @objc
    func handleCardTap(recognizer:UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        default:
            break
        }
        print("Card Tapped")
    }
    
    @objc
    func handleCardPen(recognizer:UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: nextState, duration: 0.9)
        case .changed:
            let translation = recognizer.translation(in: self.reportDetailController.handleArea)
            var fractionComplete = translation.y / cardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: 0)
        case .ended:
            continueInteractiveTransition()
        default:
            break
        }
        print("Card Swiped")
    }
    
    func animateTransitionIfNeeded (state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.reportDetailController.view.frame.origin.y = self.view.frame.height - self.cardHeight
                case .collapsed:
                    self.view.sendSubviewToBack(self.visualEffectView)
                    self.reportDetailController.view.frame.origin.y = self.view.frame.height
                }
            }
            
            frameAnimator.addCompletion { _ in
                self.cardVisible = !self.cardVisible
                self.runningAnimations.removeAll()
            }
            
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                    self.reportDetailController.view.layer.cornerRadius = 12
                case .collapsed:
                    self.reportDetailController.view.layer.cornerRadius = 0
                }
            }
            
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
            
            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                case .collapsed:
                    self.visualEffectView.effect = nil
                }
            }
            
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
        }
    }
    
    func startInteractiveTransition(state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateInteractiveTransition(fractionCompleted:CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    func continueInteractiveTransition() {
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
    
    // https://firebase.google.com/docs/database/ios/read-and-write
    func loadData() {
        print("Start load data")
        ref?.child("trash-location").observe(.childAdded, with: { (snapshot) in
            let data = (snapshot.value as? NSDictionary)
            let title = (snapshot.value as? NSDictionary)?["title"] as? String ?? ""
            let description = snapshot.key
//            let description = (snapshot.value as? NSDictionary)?["description"] as? String ?? ""
            let date = (snapshot.value as? NSDictionary)?["date"] as? String ?? ""
            let latitude = (snapshot.value as? NSDictionary)?["latitude"] as? Double ?? 0
            let longitude = (snapshot.value as? NSDictionary)?["longitude"] as? Double ?? 0
            
            self.postData.append(["title": title, "description": description, "date": date, "latitude": latitude, "longitude": longitude])
            self.createAnnotations(locations: self.postData)
        })
    }
    
    func createAnnotations(locations: [[String: Any]]) {
        for location in locations {
            let annotations = MKPointAnnotation()
            annotations.title = location["title"] as? String
            annotations.subtitle = location["description"] as? String
            annotations.coordinate = CLLocationCoordinate2D(latitude: location["latitude"] as! CLLocationDegrees, longitude: location["longitude"] as! CLLocationDegrees)
            
            ReportMapView.addAnnotation(annotations)
        }
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
        print("Go to Report Form")
        self.performSegue(withIdentifier: "ReportFormSegue", sender: self)
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
    
    // https://stackoverflow.com/questions/37320485/swift-how-to-get-information-from-a-custom-annotation-on-clicked
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let annotation = view.annotation
        setupCard(annotation: annotation as! MKPointAnnotation)
    }
}

