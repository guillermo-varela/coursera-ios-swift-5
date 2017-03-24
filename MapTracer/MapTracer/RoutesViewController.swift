//
//  RoutesViewController.swift
//  MapTracer
//
//  Created by Guillermo Varela on 3/18/17.
//  Copyright © 2017 Guillermo Varela. All rights reserved.
//

import UIKit
import MapKit
import CoreData

protocol LandmarkHolderProtocol {
    func addLandmark(_ landmark: Landmark) -> Bool
    func addRoute(_ route: Route) -> Bool
}

class RoutesViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, LandmarkHolderProtocol {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var zoomSlider: UISlider!
    @IBOutlet weak var viewRouteButton: UIButton!
    @IBOutlet weak var saveRouteButton: UIButton!

    private let locationManager = CLLocationManager()
    private var lastLocationAnnotated: CLLocation?
    private var isFirstLocation = true
    private let distanceFilter = 1.0
    private var storedRoutes = [Route]()
    private var landmarks = [Landmark]()
    private var unsavedOverlays = [MKOverlay]()
    private var context: NSManagedObjectContext? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Rutas"
        mapView.delegate = self

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = distanceFilter
        locationManager.requestWhenInUseAuthorization()

        zoomSlider.transform = CGAffineTransform.init(rotationAngle: CGFloat(-M_PI_2))
        saveRouteButton.isHidden = true

        self.context = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
        
        let routesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "RouteEntity")
        do {
            let fetchedRoutes = try self.context?.fetch(routesFetch) as! [RouteEntity]
            for fetchedRoute in fetchedRoutes {
                var route = Route()
                route.name = fetchedRoute.value(forKey: "name") as? String
                route.description = fetchedRoute.value(forKey: "desc") as? String
                route.landmarks = [Landmark]()

                let landmarkEntities = fetchedRoute.landmarks?.array as? [LandmarkEntity]
                for landmarkEntity in landmarkEntities! {
                    var landmark = Landmark()
                    landmark.latitude = landmarkEntity.value(forKey: "latitude") as? Double
                    landmark.longitude = landmarkEntity.value(forKey: "longitude") as? Double
                    landmark.name = landmarkEntity.value(forKey: "name") as? String
                    if let image = landmarkEntity.value(forKey: "image") as! Data? {
                        landmark.image = UIImage(data: image)
                    }
                    route.landmarks?.append(landmark)
                }
                storedRoutes.append(route)
                showRoute(route, true)
            }
        } catch {
            print("Failed to fetch routes: \(error)")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareRoute))
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            mapView.showsUserLocation = true
        } else {
            locationManager.stopUpdatingLocation()
            mapView.showsUserLocation = false
            if status == .denied {
                showError("Al no aceptar, no podemos presentar tu ubicación")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first!
        mapView.centerCoordinate = location.coordinate
        if isFirstLocation {
            isFirstLocation = false
            zoomChanged()
        }
    }

    @IBAction func toggleMapType(sender: UIButton) {
        let title = sender.titleLabel?.text
        switch title! {
        case "Satélite":
            mapView.mapType = .satellite
        case "Híbrido":
            mapView.mapType = .hybrid
        default:
            mapView.mapType = .standard
        }
    }

    @IBAction func zoomChanged() {
        let delta = Double(zoomSlider.value)
        var currentRegion = mapView.region
        currentRegion.span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        mapView.region = currentRegion
    }

    @IBAction func showRoute(_ sender: UIButton) {
        if landmarks.isEmpty {
            showError("Aún no has agregado sitios")
        } else if sender.titleLabel?.text == "Ver Ruta" {
            for index in 0...landmarks.count {
                if (index + 1 < landmarks.count) {
                    findRoute(landmarks[index].toMKMapItem(), landmarks[index + 1].toMKMapItem(), false)
                }
            }
            findRoute(landmarks[landmarks.count - 1].toMKMapItem(), MKMapItem.forCurrentLocation(), false)
        } else {
            mapView.removeOverlays(self.unsavedOverlays)
            viewRouteButton.setTitle("Ver Ruta", for: .normal)
            self.saveRouteButton.isHidden = true
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }

    @IBAction func shareRoute(_ sender: UIBarButtonItem) {
        let text = "Mira esta ruta"
        let names = self.landmarks.map({$0.name!}).joined(separator: ", ")
        let shareObjects = [text, names] as [Any]

        let activity = UIActivityViewController(activityItems: shareObjects, applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = self.view
        self.present(activity, animated: true)
    }

    private func showRoute(_ route: Route, _ stored: Bool) {
        if let routeLandmarks = route.landmarks {
            for index in 0...routeLandmarks.count {
                if (index + 1 < routeLandmarks.count) {
                    addMark(routeLandmarks[index].toMKMapItem())
                    findRoute(routeLandmarks[index].toMKMapItem(), routeLandmarks[index + 1].toMKMapItem(), stored)
                }
            }
            addMark(routeLandmarks[routeLandmarks.count - 1].toMKMapItem())
        }
    }

    private func addMark(_ point: MKMapItem) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = point.placemark.coordinate
        annotation.title = point.name
        mapView.addAnnotation(annotation);
    }

    private func findRoute(_ origin: MKMapItem, _ destination: MKMapItem, _ stored: Bool) {
        let request = MKDirectionsRequest()
        request.source = origin
        request.destination = destination
        request.transportType = .walking
        let directions = MKDirections(request: request)

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        directions.calculate(completionHandler: {(response, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if error != nil {
                self.showError((error?.localizedDescription)!)
                if !stored {
                    self.viewRouteButton.setTitle("Ver Ruta", for: .normal)
                    self.saveRouteButton.isHidden = true
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                }
            } else {
                self.showRoute(response!, stored)
                self.mapView.centerCoordinate = origin.placemark.coordinate
                if !stored {
                    self.viewRouteButton.setTitle("Quitar Ruta", for: .normal)
                    self.saveRouteButton.isHidden = false
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }
        })
    }

    private func showRoute(_ response: MKDirectionsResponse, _ stored: Bool) {
        for route in response.routes {
            if !stored {
                unsavedOverlays.append(route.polyline)
            }
            mapView.add(route.polyline, level: .aboveRoads)
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 3.0
        return renderer
    }

    // MARK: - Landmarks Holder Protocol
    func addLandmark(_ landmark: Landmark) -> Bool {
        if !self.landmarks.contains(landmark) {
            addMark(landmark.toMKMapItem())
            self.landmarks.append(landmark)
            return true
        }
        return false
    }

    func addRoute(_ route: Route) -> Bool {
        if !self.storedRoutes.contains(route) {
            self.storedRoutes.append(route)
            self.unsavedOverlays.removeAll()
            self.viewRouteButton.setTitle("Ver Ruta", for: .normal)
            self.saveRouteButton.isHidden = true
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            return true
        }
        return false
    }

    /*
     // MARK: - Navigation
     */

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination.isMember(of: AddLandmarkViewController.self) {
            let addLandmarkViewController = segue.destination as! AddLandmarkViewController
            addLandmarkViewController.landmarkHolder = self
            addLandmarkViewController.location = mapView.centerCoordinate
        } else if segue.destination.isMember(of: AddRouteViewController.self) {
            let addRouteViewController = segue.destination as! AddRouteViewController
            addRouteViewController.landmarkHolder = self
            addRouteViewController.landmarks = self.landmarks
        }
    }

    private func showError(_ message : String) {
        let alertController = UIAlertController(title: "Ups", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in}))
        self.present(alertController, animated: true, completion: nil)
    }
}
