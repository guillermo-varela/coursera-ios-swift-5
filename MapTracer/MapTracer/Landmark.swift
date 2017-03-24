//
//  Landmark.swift
//  MapTracer
//
//  Created by Guillermo Varela on 3/19/17.
//  Copyright © 2017 Guillermo Varela. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import MapKit

struct Landmark: Equatable {
    var latitude: CLLocationDegrees?
    var longitude: CLLocationDegrees?
    var name: String?
    var image: UIImage?

    public func toMKMapItem() -> MKMapItem {
        let landmarkLocation = CLLocationCoordinate2D(latitude: self.latitude!, longitude: self.longitude!)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: landmarkLocation, addressDictionary: nil))
        mapItem.name = self.name
        return mapItem
    }

    static func == (lhs: Landmark, rhs: Landmark) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
