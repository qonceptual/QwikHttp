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
        
        QwikHttpDefaults.setDefaultTimeOut(300)
        QwikHttpDefaults.setDefaultParameterType(.json)
        QwikHttpDefaults.setDefaultLoadingTitle("Loading")
        QwikHttpDefaults.setDefaultCachePolicy(.ReloadIgnoringLocalCacheData)
        
        sendRequest()
    }
    
    @IBAction func sendRequest()
    {
        i++
        
        if(i == 0)
        {
            //call a get to the itunes search api and find our top overall paid apps on the US Store.
            QwikHttp(url: "http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/sf=143441/limit=10/json", httpMethod: HttpRequestMethod.get).getResponse(NSDictionary.self, handler: { (result, error, request) -> Void in
                
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
                
            })
        }
        else if (i == 1)
        {
            
            let r = Restaurant()
            r.name = String(format: "Rest Test %i", rand() % 1000)
            
            QwikHttp("http://resttest2016.herokuapp.com/restaurants", httpMethod: .post).setLoadingTitle("Creating").setObject(r).addUrlParams(["format" : "json"]).getResponse(Restaurant.self, handler: { (results, error, request) -> Void in
                
                
                if let restaurant = results, name = restaurant.name
                {
                    UIAlertController.showAlertWithTitle("Success", andMessage: String(format: "We Found %@",name ), from: self)
                }
                else
                {
                    UIAlertController.showAlertWithTitle("Failure", andMessage: String(format: "Load error"), from: self)
                }
                
            })
        }
            
        else if (i == 2)
        {
            
            QwikHttp("http://resttest2016.herokuapp.com/restaurants", httpMethod: .get).addUrlParams(["format" : "json"]).getArrayResponse(Restaurant.self, handler: { (results, error, request) -> Void in
                
                if let resultsArray = results
                {
                    UIAlertController.showAlertWithTitle("Success", andMessage: String(format: "We Found %li",resultsArray.count), from: self)
                }
                else
                {
                    UIAlertController.showAlertWithTitle("Failure", andMessage: String(format: "Load error"), from: self)
                }
                
            })
            
        }
        
        else if (i == 3)
        {
            QwikHttp("http://resttest2016.herokuapp.com/restaurants/1", httpMethod: .get).addUrlParams(["format" : "json"]).send({ (success) -> Void in
                
                if success
                {
                    UIAlertController.showAlertWithTitle("Load Successful", andMessage:"", from: self)
                }
                else
                {
                    UIAlertController.showAlertWithTitle("Failure", andMessage: String(format: "Load error"), from: self)
                }
                
            })
            
            i = -1;
        }
        
    }

}

