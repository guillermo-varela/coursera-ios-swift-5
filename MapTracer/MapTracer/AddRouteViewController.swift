//
//  AddRouteViewController.swift
//  MapTracer
//
//  Created by Guillermo Varela on 3/20/17.
//  Copyright © 2017 Guillermo Varela. All rights reserved.
//

import UIKit
import CoreData

class AddRouteViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!

    var landmarks: [Landmark]!
    var landmarkHolder: LandmarkHolderProtocol!

    private var context: NSManagedObjectContext? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Nueva Ruta"
        self.context = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
    }

    @IBAction func saveRoute() {
        if landmarks.count <= 1 {
            showMessage("Ups", "Necesitas más de un sitio en la ruta.")
        } else if nameTextField.text == nil || nameTextField.text!.isEmpty {
            showMessage("Ups", "Nombre inválido.")
        } else if descriptionTextField.text == nil || descriptionTextField.text!.isEmpty {
            showMessage("Ups", "Descripción inválida.")
        } else {
            let route = Route(landmarks: landmarks, name: nameTextField.text!, description: descriptionTextField.text!)

            if landmarkHolder.addRoute(route) {
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
                    showMessage("Éxito", "Ruta agregada.")
                } catch {
                    showMessage("Ups", "Error guardando la ruta.")
                }
            } else {
                showMessage("Ups", "Ruta repetida.")
            }
        }
    }

    private func showMessage(_ title: String, _ message : String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in}))
        self.present(alertController, animated: true, completion: nil)
    }
}
