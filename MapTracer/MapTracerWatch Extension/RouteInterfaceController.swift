//
//  RouteInterfaceController.swift
//  MapTracer
//
//  Created by Guillermo Varela on 3/26/17.
//  Copyright © 2017 Guillermo Varela. All rights reserved.
//

import WatchKit

class RouteInterfaceController: WKInterfaceController {

    @IBOutlet var interfaceMap: WKInterfaceMap!

    var route: Route?

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        route = context as? Route
        self.setTitle(route?.name)

        let landmarks = (route?.landmarks)!
        for index in 0..<min(landmarks.count, 5) {
            let landmark = landmarks[index]
            interfaceMap.addAnnotation(landmark.toCLLocationCoordinate2D(), with: .purple)
        }

        let region = MKCoordinateRegion(center: landmarks[0].toCLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        interfaceMap.setRegion(region)
    }

    @IBAction func zoom(_ value: Float) {
        let degrees = CLLocationDegrees(value) / 100
        let spanMake = MKCoordinateSpanMake(degrees, degrees)

        let landmarks = (route?.landmarks)!
        let region = MKCoordinateRegionMake(landmarks[0].toCLLocationCoordinate2D(), spanMake)
        interfaceMap.setRegion(region)
    }
}
