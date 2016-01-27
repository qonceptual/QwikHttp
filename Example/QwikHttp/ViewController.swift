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

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        sendRequest()
    }
    
    @IBAction func sendRequest()
    {
        MBProgressHUD.showWithTitle("Loading")
        
        //call a get to the itunes search api and find our top overall paid apps on the US Store.
        QwikHttp(urlString: "http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/sf=143441/limit=10/json", httpMethod: HttpRequestMethod.get).dictionaryResponse{ (responseDictionary) -> Void in
            
            //parse our feed object from the response
            if let feed = responseDictionary["feed"] as? NSDictionary, let entries = feed["entry"] as? NSArray
            {
                //note, this handy helper comes from seaseAssist pod
                UIAlertController.showAlertWithTitle("Success", andMessage: String(format: "We Found %li",entries.count), from: self)
            }
                
                //show an error if we could parse through our dictionary
            else
            {
                UIAlertController.showAlertWithTitle("Failure", andMessage: "Error parsing the result", from: self)
            }
            
            //show an alert with our error if one occurred
            }.errorResponse { (errorResponse, error, statusCode) -> Void in
                
                UIAlertController.showAlertWithTitle("Failure", andMessage: error.localizedDescription, from: self)
            }.send { (success) -> Void in
                
                //hide our progress dialog no matter what happens
                MBProgressHUD.hide()
        }
    }

}

