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
import WatchConnectivity

protocol LandmarkHolderProtocol {
    func addLandmark(_ landmark: Landmark) -> Bool
}

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, LandmarkHolderProtocol {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var zoomSlider: UISlider!
    @IBOutlet weak var viewRouteButton: UIButton!
    @IBOutlet weak var saveRouteButton: UIButton!
    @IBOutlet weak var addLandmarkButton: UIButton!

    var currentRoute: Route?
    var storedRoutes = [Route]()
    private var context: NSManagedObjectContext? = nil
    private let locationManager = CLLocationManager()
    private var isFirstLocation = true
    private let distanceFilter = 1.0
    private var landmarks = [Landmark]()

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self

        context = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = distanceFilter
        locationManager.requestWhenInUseAuthorization()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareRoute))
        zoomSlider.transform = CGAffineTransform.init(rotationAngle: CGFloat(-M_PI_2))
        saveRouteButton.isHidden = true

        if currentRoute != nil {
            showRoute(currentRoute!)
            showAvailableRouteButtons(.stored)
        } else {
            showAvailableRouteButtons(.view)
        }
    }

    override func viewWillDisappear(_ animated : Bool) {
        super.viewWillDisappear(animated)

        if self.isMovingFromParentViewController && (self.navigationController?.viewControllers[1].isMember(of: RoutesTableViewController.self))! {
            let controller = self.navigationController?.viewControllers[1] as! RoutesTableViewController
            controller.storedRoutes = self.storedRoutes
        }
    }
    
    // MARK: - Location
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            if currentRoute == nil {
                locationManager.startUpdatingLocation()
                mapView.showsUserLocation = true
            } else {
                self.zoomChanged()
            }
        } else {
            locationManager.stopUpdatingLocation()
            mapView.showsUserLocation = false
            if status == .denied {
                showMessage("Ups", "Al no aceptar, no podemos presentar tu ubicación")
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

    // MARK: - Map
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

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination.isMember(of: AddLandmarkViewController.self) {
            let addLandmarkViewController = segue.destination as! AddLandmarkViewController
            addLandmarkViewController.landmarkHolder = self
            addLandmarkViewController.location = mapView.centerCoordinate
        } else if segue.destination.isMember(of: RoutesTableViewController.self) {
            let controller = segue.destination as! RoutesTableViewController
            controller.storedRoutes = self.storedRoutes
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
            showMessage("Ups", "Aún no has agregado sitios")
        } else if sender.titleLabel?.text == "Ver Ruta" {
            for index in 0...landmarks.count {
                if (index + 1 < landmarks.count) {
                    findRoute(landmarks[index].toMKMapItem(), landmarks[index + 1].toMKMapItem())
                }
            }
            findRoute(landmarks[landmarks.count - 1].toMKMapItem(), MKMapItem.forCurrentLocation())
        } else {
            mapView.removeOverlays(mapView.overlays)
            self.showAvailableRouteButtons(.view)
        }
    }

    @IBAction func presentSaveRouteAlert() {
        if landmarks.count <= 1 {
            showMessage("Ups", "Necesitas más de un sitio en la ruta.")
        } else {
            let alertController = UIAlertController(title: "Guardar Ruta", message: nil, preferredStyle: .alert)

            alertController.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))

            alertController.addAction(UIAlertAction(title: "Guardar", style: .default, handler: {
                alert -> Void in
                let nameTextField = alertController.textFields![0] as UITextField
                let descriptionTextField = alertController.textFields![1] as UITextField
                self.saveRoute(nameTextField.text, descriptionTextField.text)
            }))

            alertController.addTextField(configurationHandler: { (textField) -> Void in
                textField.placeholder = "Nombre"
                textField.textAlignment = .center
            })

            alertController.addTextField(configurationHandler: { (textField) -> Void in
                textField.placeholder = "Descripción"
                textField.textAlignment = .center
            })

            self.present(alertController, animated: true, completion: nil)
        }
    }

    @IBAction func shareRoute(_ sender: UIBarButtonItem) {
        let text = "Mira esta ruta"
        let sharingRoutes: [Landmark] = currentRoute != nil ? (currentRoute?.landmarks)! : landmarks
        let names = sharingRoutes.map({$0.name!}).joined(separator: ", ")
        let shareObjects = [text, names] as [Any]
        
        let activity = UIActivityViewController(activityItems: shareObjects, applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = self.view
        self.present(activity, animated: true)
    }

    private func saveRoute(_ name: String?, _ description: String?) {
        if name == nil || name!.isEmpty {
            showMessage("Ups", "Nombre inválido.")
        } else if description == nil || description!.isEmpty {
            showMessage("Ups", "Descripción inválida.")
        } else {
            let route = Route(landmarks: landmarks, name: name!, description: description!)
            
            if self.addRoute(route) {
                let newRouteEntity = NSEntityDescription.insertNewObject(forEntityName: "RouteEntity", into: self.context!)
                newRouteEntity.setValue(route.name, forKey: "name")
                newRouteEntity.setValue(route.description, forKey: "desc")
                
                var landmarksEntities = [NSManagedObject]()
                for landmark in landmarks {
                    let landmarkEntity = NSEntityDescription.insertNewObject(forEntityName: "LandmarkEntity", into: self.context!)
                    landmarkEntity.setValue(landmark.latitude, forKey: "latitude")
                    landmarkEntity.setValue(landmark.longitude, forKey: "longitude")
                    landmarkEntity.setValue(landmark.name, forKey: "name")
                    if landmark.image != nil {
                        landmarkEntity.setValue(UIImagePNGRepresentation(landmark.image!), forKey: "image")
                    }
                    landmarksEntities.append(landmarkEntity)
                }
                newRouteEntity.setValue(NSOrderedSet(array: landmarksEntities), forKey: "landmarks")
                do {
                    try self.context?.save()
                    currentRoute = route
                    showAvailableRouteButtons(.stored)
                    showMessage("Éxito", "Ruta agregada.")
                } catch {
                    showMessage("Ups", "Error guardando la ruta.")
                }
            } else {
                showMessage("Ups", "Ruta repetida.")
            }
        }
    }

    private func addRoute(_ route: Route) -> Bool {
        if !self.storedRoutes.contains(route) {
            self.storedRoutes.append(route)
            showAvailableRouteButtons(.remove)
            return true
        }
        return false
    }

    private func showRoute(_ route: Route) {
        if let routeLandmarks = route.landmarks {
            for index in 0...routeLandmarks.count {
                if (index + 1 < routeLandmarks.count) {
                    addMark(routeLandmarks[index].toMKMapItem())
                    findRoute(routeLandmarks[index].toMKMapItem(), routeLandmarks[index + 1].toMKMapItem())
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
    
    private func findRoute(_ origin: MKMapItem, _ destination: MKMapItem) {
        let request = MKDirectionsRequest()
        request.source = origin
        request.destination = destination
        request.transportType = .walking
        let directions = MKDirections(request: request)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        directions.calculate(completionHandler: {(response, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if error != nil {
                self.showMessage("Ups", (error?.localizedDescription)!)
                if self.currentRoute == nil {
                    self.showAvailableRouteButtons(.view)
                }
            } else {
                self.showRoute(response!)
                self.mapView.centerCoordinate = origin.placemark.coordinate
                if self.currentRoute == nil {
                    self.showAvailableRouteButtons(.remove)
                }
            }
        })
    }

    private func showRoute(_ response: MKDirectionsResponse) {
        for route in response.routes {
            mapView.add(route.polyline, level: .aboveRoads)
        }
    }

    private func showAvailableRouteButtons(_ state: RouteButtonsState) {
        switch state {
        case .view:
            self.viewRouteButton.setTitle("Ver Ruta", for: .normal)
            self.saveRouteButton.isHidden = true
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        case .remove:
            self.viewRouteButton.setTitle("Quitar Ruta", for: .normal)
            self.saveRouteButton.isHidden = false
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        case .stored :
            self.viewRouteButton.setTitle("Ver Ruta", for: .normal)
            self.viewRouteButton.isEnabled = false
            self.saveRouteButton.isHidden = true
            self.addLandmarkButton.isEnabled = false
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }

    private func showMessage(_ title : String, _ message : String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in}))
        self.present(alertController, animated: true, completion: nil)
    }
}
