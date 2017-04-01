//
//  EventViewController.swift
//  MapTracer
//
//  Created by Guillermo Varela on 3/28/17.
//  Copyright © 2017 Guillermo Varela. All rights reserved.
//

import UIKit

class EventsTableViewController: UITableViewController {

    let url = "https://api.myjson.com/bins/g806b"
    let dateFormatter = DateFormatter()
    var events = [Event]()

    override func viewDidLoad() {
        super.viewDidLoad()

        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        let urlRequest = URLRequest(url: URL(string: url)!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        let session = URLSession(configuration: URLSessionConfiguration.default)

        let dataTask = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false

                guard error == nil else {
                    self.showMessage("Ups", "Error consultando, por favor verifica tu conexión a Internet.")
                    return
                }

                if let data = data {
                    do {
                        guard let eventsDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: AnyObject]] else {
                            self.showMessage("Ups", "Error procesando la respuesta del servidor.")
                            return
                        }
                        if eventsDictionary.count == 0 {
                            self.showMessage("Ups", "No se encontraron eventos.")
                        } else {
                            self.buildEvents(eventsDictionary)
                        }
                    } catch  {
                        self.showMessage("Ups", "Error procesando la respuesta del servidor.")
                    }
                } else {
                    self.showMessage("Ups", "No se obtuvo una respuesta del servidor, por favor intenta de nuevo más tarde.")
                }
            }
        })
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        dataTask.resume()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! EventTableViewCell
        let event = events[indexPath.row]

        cell.nameLabel.text = event.name
        cell.descriptionLabel.text = event.description
        cell.dateLabel.text = dateFormatter.string(from: event.date)

        return cell
    }

    private func buildEvents(_ eventsDictionary: [[String: AnyObject]]) {
        

        for eventDictinary in eventsDictionary {
            let eventDate = dateFormatter.date(from: eventDictinary["fecha"] as! String)
            let event = Event(name: eventDictinary["nombre"] as! String, description: eventDictinary["description"] as! String, date: eventDate!)
            events.append(event)
        }

        self.tableView.reloadData()
    }

    private func showMessage(_ title : String, _ message : String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in}))
        self.present(alertController, animated: true, completion: nil)
    }
}
