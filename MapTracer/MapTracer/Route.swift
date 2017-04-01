//
//  Route.swift
//  MapTracer
//
//  Created by Guillermo Varela on 3/20/17.
//  Copyright © 2017 Guillermo Varela. All rights reserved.
//

import Foundation

struct Route: Equatable {
    var landmarks: [Landmark]?
    var name: String?
    var description: String?

    public func toDictionary() -> [String : Any] {
        var landmarksDictionary = [[String : Any]]()
        if let routeLandmarks = landmarks {
            for landmark in routeLandmarks {
                landmarksDictionary.append(landmark.toDictionary())
            }
        }
        return ["name": name!, "description": description!, "landmarks": landmarksDictionary]
    }
    
    public static func fromDictionary(data: [String : Any]) -> Route {
        var route = Route()
        route.name = data["name"] as! String?
        route.description = data["description"] as! String?
        route.landmarks = [Landmark]()

        let landmarksArray = data["landmarks"] as! [[String : Any]]
        for landmarkDictionary in landmarksArray {
            route.landmarks?.append(Landmark.fromDictionary(data: landmarkDictionary))
        }

        return route
    }

    static func == (lhs: Route, rhs: Route) -> Bool {
        return lhs.name! == rhs.name! || lhs.landmarks! == rhs.landmarks!
    }
}
