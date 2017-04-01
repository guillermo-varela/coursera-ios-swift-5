//
//  InterfaceController.swift
//  MapTracerWatch Extension
//
//  Created by Guillermo Varela on 3/25/17.
//  Copyright © 2017 Guillermo Varela. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    @IBOutlet var noRoutesLabel: WKInterfaceLabel!
    @IBOutlet var routesTable: WKInterfaceTable!

    private var routes = [Route]()

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if (WCSession.isSupported()) {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Session status: \(activationState)")
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        let route = Route.fromDictionary(data: userInfo)
        if !routes.contains(route) {
            routes.append(route)
            routesTable.setNumberOfRows(routes.count, withRowType: "RouteRow")
            noRoutesLabel.setHidden(true)
            
            for index in 0..<routesTable.numberOfRows {
                guard let controller = routesTable.rowController(at: index) as? RouteRowController else { continue }
                controller.route = routes[index]
            }
        }
    }

    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        return routes[rowIndex]
    }
}
