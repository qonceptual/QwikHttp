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

    //an index variable to keep track of the # of requests we've sent
    var i = -1
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //configure qwikHttp
        QwikHttpConfig.setDefaultTimeOut(300)
        QwikHttpConfig.defaultParameterType = .Json
        QwikHttpConfig.defaultLoadingTitle = "Loading"
        QwikHttpConfig.defaultCachePolicy = .ReloadIgnoringLocalCacheData
        
        //set our loading indicator and response interceptor. This isn't required, but done just for test
        //and example
        QwikHttpConfig.loadingIndicatorDelegate = QwikHelper.shared()
        QwikHttpConfig.responseInterceptor = QwikHelper.shared()
        
        //send our first request
        sendRequest()
    }
    
    @IBAction func sendRequest()
    {
        i++
        
        if(i == 0)
        {
            //call a get to the itunes search api and find our top overall paid apps on the US Store.
            QwikHttp(url: "http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/sf=143441/limit=10/json", httpMethod: HttpRequestMethod.Get).getResponse(NSDictionary.self,  { (result, error, request) -> Void in
                
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
            //replace the custom indicator with the default loader
            QwikHttpConfig.loadingIndicatorDelegate = nil
            
            let r = Restaurant()
            r.name = String(format: "Rest Test %i", rand() % 1000)
            
            //create a new restaurant
            QwikHttp("http://resttest2016.herokuapp.com/restaurants", httpMethod: .Post).setLoadingTitle("Creating").setObject(r).addUrlParams(["format" : "json"]).getResponse(Restaurant.self, { (results, error, request) -> Void in
                
                //get the restaurant from the response
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
            //get an array of restaurants
            QwikHttp("http://resttest2016.herokuapp.com/restaurants", httpMethod: .Get).addUrlParams(["format" : "json"]).getArrayResponse(Restaurant.self, { (results, error, request) -> Void in
                
                //display the restaurant count
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
            //call a get with a specific restaurant. This is an example of the basic boolean result handler
            //no response info is available, but you can quickly determine if the response was successful or not.
            QwikHttp("http://resttest2016.herokuapp.com/restaurants/1", httpMethod: .Get).addUrlParams(["format" : "json"]).send({ (success) -> Void in
                
                if success
                {
                    UIAlertController.showAlertWithTitle("Load Successful", andMessage:"", from: self)
                }
                else
                {
                    UIAlertController.showAlertWithTitle("Failure", andMessage: String(format: "Load error"), from: self)
                }
            })
            
            //reset our request counter
            i = -1;
        }
        
    }

}

