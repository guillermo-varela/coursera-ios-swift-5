//
//  AboutViewController.swift
//  MapTracer
//
//  Created by Guillermo Varela on 3/28/17.
//  Copyright © 2017 Guillermo Varela. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func openHDAugmentedReality() {
        if let url = URL(string: "https://github.com/DanijelHuis/HDAugmentedReality") {
            UIApplication.shared.openURL(url)
        }
    }
}
