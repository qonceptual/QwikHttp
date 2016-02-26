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

    var i = -1
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        sendRequest()
    }
    
    @IBAction func sendRequest()
    {
        i++
        
        if(i == 0)
        {
            //call a get to the itunes search api and find our top overall paid apps on the US Store.
            QwikHttp<NSDictionary>(urlString: "http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/sf=143441/limit=10/json", httpMethod: HttpRequestMethod.get).setLoadingTitle("Loading from iTunes").getResponse({ (result, error, request) -> Void in
                
                //parse our feed object from the response
                if let dict = result, let feed = dict["feed"] as? NSDictionary, let entries = feed["entry"] as? NSArray
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
            })
        }
        else if (i == 1)
        {
            
            let r = Restaurant()
            r.name = String(format: "Rest Test %i", rand() % 1000)
            
            QwikHttp<Restaurant>(urlString: "http://resttest2016.herokuapp.com/restaurants", httpMethod: .post).setLoadingTitle("Creating").setObject(r).addUrlParams(["format" : "json"]).getResponse({ (results, error, request) -> Void in
                
                
                if let restaurant = results, name = restaurant.name
                {
                    UIAlertController.showAlertWithTitle("Success", andMessage: String(format: "We Found %@",name ), from: self)
                }
                
            })
        }
            
        else if (i == 2)
        {
            
            QwikHttp<Restaurant>(urlString: "http://resttest2016.herokuapp.com/restaurants", httpMethod: .get).setLoadingTitle("Searching Restaurants").addUrlParams(["format" : "json"]).getArrayResponse({ (results, error, request) -> Void in
                
                if let resultsArray = results
                {
                    UIAlertController.showAlertWithTitle("Success", andMessage: String(format: "We Found %li",resultsArray.count), from: self)
                }
                
            })
            
            i = 0;
        }
        
    }

}

