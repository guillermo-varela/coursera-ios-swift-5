//
//  QrViewController.swift
//  MapTracer
//
//  Created by Guillermo Varela on 3/18/17.
//  Copyright © 2017 Guillermo Varela. All rights reserved.
//

import UIKit

class QrViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var qrContentLabel: UILabel!
    @IBOutlet weak var webView: UIWebView!

    var url: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "QR"
        self.webView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        setupNavigationBar()

        if var urlValue = url {
            if !urlValue.hasPrefix("http") || !urlValue.hasPrefix("https") {
                urlValue = "http://" + urlValue
            }
            qrContentLabel.text = urlValue
            let request = URLRequest(url: URL(string: urlValue)!)
            webView.loadRequest(request)
        }
    }

    private func setupNavigationBar() {
        self.navigationItem.hidesBackButton = true

        let newBackButton = UIBarButtonItem(title: "< Atrás", style: UIBarButtonItemStyle.plain, target: self, action: #selector(QrViewController.popToSecondPrevious(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
    }

    func popToSecondPrevious(sender: UIBarButtonItem) {
        // Minus 3 because the current view is on the last stack position
        let index = max(((self.navigationController?.viewControllers.count)! - 3), 0)
        let controller = self.navigationController?.viewControllers[index]
        _ = self.navigationController?.popToViewController(controller!, animated: true)
    }

    func webViewDidStartLoad(_ webView: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
