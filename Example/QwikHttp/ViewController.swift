//
//  ViewController.swift
//  QwikHttp
//
//  Created by Logan Sease on 01/27/2016.
//  Copyright (c) 2016 Logan Sease. All rights reserved.
//

import UIKit
import QwikHttp
import SeaseAssist

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        MBProgressHUD.showWithTitle("Loading")
        
        //call a get to the itunes search api and find our top overall paid apps on the US Store.
        QwikHttp(urlString: "http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/sf=143441/limit=10/json", httpMethod: HttpRequestMethod.get).dictionaryResponse{ (responseDictionary) -> Void in
            
            if let feed = responseDictionary["feed"] as? NSDictionary, let entries = feed["entry"] as? NSArray
            {
                //note, this handy helper comes from seaseAssist pod
                UIAlertController.showAlertWithTitle("Success", andMessage: String(format: "We Found %li",entries.count), from: self)
            }
            else
            {
                UIAlertController.showAlertWithTitle("Failure", andMessage: "Error parsing the result", from: self)
            }
            
            }.errorResponse { (errorResponse, error, statusCode) -> Void in
                UIAlertController.showAlertWithTitle("Failure", andMessage: error.localizedDescription, from: self)
            }.send { (success) -> Void in
                 MBProgressHUD.hide()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

