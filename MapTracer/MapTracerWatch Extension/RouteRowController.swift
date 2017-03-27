//
//  RouteRowController.swift
//  MapTracer
//
//  Created by Guillermo Varela on 3/26/17.
//  Copyright © 2017 Guillermo Varela. All rights reserved.
//

import WatchKit

class RouteRowController: NSObject {

    @IBOutlet var routeLabel: WKInterfaceLabel!

    var route: Route? {
        didSet {
            guard let route = route else { return }
            routeLabel.setText(route.name)
        }
    }
}
