//
//  RoutesTableViewController.swift
//  MapTracer
//
//  Created by Guillermo Varela on 3/26/17.
//  Copyright © 2017 Guillermo Varela. All rights reserved.
//

import UIKit

class RoutesTableViewController: UITableViewController {

    var storedRoutes = [Route]()

    override func viewWillAppear(_ animated: Bool) {
        if storedRoutes.count > 0 {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(goToMapView))
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return storedRoutes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "routeCell", for: indexPath)
        cell.textLabel?.text = storedRoutes[indexPath.row].name
        return cell
    }

    // MARK: - Navigation

    @objc private func goToMapView() {
        performSegue(withIdentifier: "mapSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination.isMember(of: MapViewController.self) {
            let controller = segue.destination as! MapViewController
            controller.storedRoutes = self.storedRoutes
            if let selectedRowIndex = self.tableView.indexPathForSelectedRow?.row {
                controller.currentRoute = storedRoutes[selectedRowIndex]
            }
        }
    }
}
