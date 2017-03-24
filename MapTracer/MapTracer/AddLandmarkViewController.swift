//
//  AddLandmarkViewController.swift
//  MapTracer
//
//  Created by Guillermo Varela on 3/19/17.
//  Copyright © 2017 Guillermo Varela. All rights reserved.
//

import UIKit
import MapKit

class AddLandmarkViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var location: CLLocationCoordinate2D!
    var landmarkHolder: LandmarkHolderProtocol!

    @IBOutlet weak var lattitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var pictureImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Agregar Sitio"
    }

    override func viewWillAppear(_ animated: Bool) {
        lattitudeLabel.text = String(location.latitude)
        longitudeLabel.text = String(location.longitude)
    }

    @IBAction func selectPictureSource() {
        let alertController = UIAlertController(title: "Foto", message: "Selecciona el origen de la foto", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cámara", style: .default, handler: {action in self.takePicture()}))
        alertController.addAction(UIAlertAction(title: "Galería", style: .default, handler: {action in self.openPhotoLibraryButton()}))
        self.present(alertController, animated: true, completion: nil)
    }

    private func takePicture() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera;
            imagePicker.allowsEditing = false
            imagePicker.modalPresentationStyle = .fullScreen
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            showError("No se puede acceder a la cámara")
        }
    }

    private func openPhotoLibraryButton() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            showError("No se puede acceder a la galería")
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        pictureImageView.contentMode = .scaleAspectFit
        pictureImageView.image = chosenImage
        dismiss(animated:true, completion: nil)
    }

    @IBAction func addLandmark() {
        if nameTextField.text == nil || nameTextField.text!.isEmpty {
            showError("Nombre inválido.")
        } else {
            let landmark = Landmark(latitude: location.latitude, longitude: location.longitude, name: nameTextField.text!, image: pictureImageView.image)
            if landmarkHolder.addLandmark(landmark) {
                if let navController = self.navigationController {
                    navController.popViewController(animated: true)
                }
            } else {
                showError("Lugar repetido.")
            }
        }
    }

    private func showError(_ message : String) {
        let alertController = UIAlertController(title: "Ups", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in}))
        self.present(alertController, animated: true, completion: nil)
    }
}
