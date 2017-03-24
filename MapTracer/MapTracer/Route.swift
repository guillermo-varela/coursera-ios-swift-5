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

    static func == (lhs: Route, rhs: Route) -> Bool {
        return lhs.name! == rhs.name! || lhs.landmarks! == rhs.landmarks!
    }
}
