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

    public func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
    }

    public func toDictionary() -> [String : Any] {
        return ["name": name!, "latitude": latitude!, "longitude": longitude!]
    }

    public static func fromDictionary(data: [String : Any]) -> Landmark {
        var landmark = Landmark()
        landmark.name = data["name"] as! String?
        landmark.latitude = data["latitude"] as! CLLocationDegrees?
        landmark.longitude = data["longitude"] as! CLLocationDegrees?
        return landmark
    }

    static func == (lhs: Landmark, rhs: Landmark) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
