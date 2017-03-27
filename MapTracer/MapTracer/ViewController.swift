//
//  ViewController.swift
//  MapTracer
//
//  Created by Guillermo Varela on 3/18/17.
//  Copyright © 2017 Guillermo Varela. All rights reserved.
//

import UIKit
import CoreData
import WatchConnectivity

class ViewController: UIViewController, WCSessionDelegate {

    private var storedRoutes = [Route]()
    private var context: NSManagedObjectContext? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.context = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
        
        let routesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "RouteEntity")
        do {
            let fetchedRoutes = try self.context?.fetch(routesFetch) as! [RouteEntity]
            for fetchedRoute in fetchedRoutes {
                var route = Route()
                route.name = fetchedRoute.value(forKey: "name") as? String
                route.description = fetchedRoute.value(forKey: "desc") as? String
                route.landmarks = [Landmark]()
                
                let landmarkEntities = fetchedRoute.landmarks?.array as? [LandmarkEntity]
                for landmarkEntity in landmarkEntities! {
                    var landmark = Landmark()
                    landmark.latitude = landmarkEntity.value(forKey: "latitude") as? Double
                    landmark.longitude = landmarkEntity.value(forKey: "longitude") as? Double
                    landmark.name = landmarkEntity.value(forKey: "name") as? String
                    if let image = landmarkEntity.value(forKey: "image") as! Data? {
                        landmark.image = UIImage(data: image)
                    }
                    route.landmarks?.append(landmark)
                }
                storedRoutes.append(route)
            }
        } catch {
            print("Failed to fetch routes: \(error)")
        }
        
        if (WCSession.isSupported()) {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }

    /*
     // MARK: - WatchKit
     */

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if storedRoutes.count > 0 && activationState == .activated && session.isPaired && session.isWatchAppInstalled {
            for route in storedRoutes {
                session.transferUserInfo(route.toDictionary())
            }
        }
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("Watch session inactive")
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        print("Watch session deactivated")
    }

    /*
     // MARK: - Navigation
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination.isMember(of: RoutesTableViewController.self) {
            let controller = segue.destination as! RoutesTableViewController
            controller.storedRoutes = self.storedRoutes
        }
    }
}
