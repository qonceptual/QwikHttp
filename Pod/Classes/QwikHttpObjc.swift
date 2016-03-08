//
//  QwikHttp.swift
//  oAuthExample
//
//  Created by Logan Sease on 1/26/16.
//  Copyright © 2016 Logan Sease. All rights reserved.
//

import Foundation
import QwikJson
import SwiftSpinner


//the main request object
@objc public class QwikHttpObjc : NSObject {
    
    /***** REQUEST VARIABLES ******/
    private var urlString : String!
    private var httpMethod : HttpRequestMethod!
    private var headers : [String : String]!
    private var params : [String : AnyObject]!
    private var body: NSData?
    private var parameterType : ParameterType!
    
    //response variables
    public var responseError : NSError?
    public var responseData : NSData?
    public var response: NSURLResponse?
    public var responseString : NSString?
    
    //handlers
    //private var genericHandler : ResponseHandler?
    //private var genericArrayHandler : ArrayResponseHandler?
    private var booleanHandler : BooleanCompletionHandler?
    
    //class params
    private var timeOut : Double!
    private var cachePolicy: NSURLRequestCachePolicy!
    private var loadingTitle: String?
    
    /**** REQUIRED INITIALIZER*****/
    public convenience init(url: String!, httpMethod: HttpRequestMethod!)
    {
        self.init(url,httpMethod: httpMethod)
    }
    
    @objc public init(_ url: String!, httpMethod: HttpRequestMethod)
    {
        self.urlString = url
        self.httpMethod = httpMethod
        self.headers = [:]
        self.params = [:]
        
        //set defaults
        self.parameterType = QwikHttpDefaults.defaultParameterType
        self.cachePolicy = QwikHttpDefaults.defaultCachePolicy
        self.timeOut = QwikHttpDefaults.defaultTimeOut
        self.loadingTitle = QwikHttpDefaults.defaultLoadingTitle
    }
    
    /**** ADD / SET VARIABLES. ALL RETURN SELF TO ENCOURAGE SINGLE LINE BUILDER TYPE SYNTAX *****/
    @objc public func addParam(key : String!, value: String!) -> QwikHttpObjc
    {
        params[key] = value
        return self
    }
    @objc public func addHeader(key : String!, value: String!) -> QwikHttpObjc
    {
        headers[key] = value
        return self
    }
    
    @objc public func setLoadingTitle(title: String?) -> QwikHttpObjc
    {
        self.loadingTitle = title
        return self
    }
    
    @objc public func addUrlParams(params: [String: String]!) -> QwikHttpObjc
    {
        //start our URL Parameters
        if let _ = urlString.rangeOfString("?")
        {
            urlString = urlString + "&"
        }
        else
        {
            urlString = urlString + "?"
        }
        urlString = urlString + QwikHttp.paramStringFrom(params)
        return self
    }
    
    @objc public func setObject(object: QwikJson?)  -> QwikHttpObjc
    {
        if let qwikJson = object,  params = qwikJson.toDictionary() as? [String : AnyObject]
        {
            self.addParams(params)
            self.setParameterType(.Json)
        }
        return self
    }
    
    @objc public func addParams(params: [String: AnyObject]!) -> QwikHttpObjc
    {
        self.params = combinedDictionary(self.params, with: params)
        return self
    }
    
    @objc public func addHeaders(headers: [String: String]!) -> QwikHttpObjc
    {
        self.headers = combinedDictionary(self.headers, with: headers) as! [String : String]
        return self
    }
    @objc public func setBody(body : NSData!) -> QwikHttpObjc
    {
        self.body = body
        return self;
    }
    @objc public func setParameterType(parameterType : ParameterType) -> QwikHttpObjc
    {
        self.parameterType = parameterType
        return self;
    }
    
    @objc public func setCachePolicy(policy: NSURLRequestCachePolicy) -> QwikHttpObjc
    {
        cachePolicy = policy
        return self
    }
    
    @objc public func setTimeOut(timeOut: Double) -> QwikHttpObjc
    {
        self.timeOut = timeOut
        return self
    }
    
    /********* RESPONSE HANDLERS / SENDING METHODS *************/
    
    
    @objc public func getStringResponse(handler :  (String?, NSError?, QwikHttpObjc!) -> Void)
    {
        HttpRequestPooler.sendRequest(self) { (data, response, error) -> Void in
         
            if let e = error
            {
                QwikHttpObjc.mainThread({ () -> () in
                    handler(nil,e, self)
                })
            }
            else
            {
                if let t : String = String.fromData(data)
                {
                    QwikHttpObjc.mainThread({ () -> () in
                        handler(t,nil,self)
                    })
                }

            }
        }
    }
    
    @objc public func getDataResponse(handler :  (NSData?, NSError?, QwikHttpObjc!) -> Void)
    {
        HttpRequestPooler.sendRequest(self) { (data, response, error) -> Void in
            
                QwikHttpObjc.mainThread({ () -> () in
                    handler(data,error, self)
                })
        }
    }
    
    @objc public func getDictionaryResponse(handler :  (NSDictionary?, NSError?, QwikHttpObjc!) -> Void)
    {
        HttpRequestPooler.sendRequest(self) { (data, response, error) -> Void in
            
            if let e = error
            {
                QwikHttpObjc.mainThread({ () -> () in
                    handler(nil,e, self)
                })
            }
            else
            {
                if let d : NSDictionary = NSDictionary.fromData(data)
                {
                    QwikHttpObjc.mainThread({ () -> () in
                        handler(d,nil,self)
                    })
                }
            }
        }
    }
    
    @objc public func getArrayResponse(handler :  ([NSDictionary]?, NSError?, QwikHttpObjc!) -> Void)
    {
        HttpRequestPooler.sendRequest(self) { (data, response, error) -> Void in
            
            if let e = error
            {
                QwikHttpObjc.mainThread({ () -> () in
                    handler(nil,e, self)
                })
            }
            else
            {
                if let d : [NSDictionary] = NSDictionary.arrayFromData(data)
                {
                    QwikHttpObjc.mainThread({ () -> () in
                        handler(d,nil,self)
                    })
                }
            }
        }
    }
    
    //Send the request!
    @objc public func send( handler: BooleanCompletionHandler? = nil)
    {
        HttpRequestPooler.sendRequest(self) { (data, response, error) -> Void in
            
            if let booleanHandler = handler
            {
                if let _ = error
                {
                    QwikHttpObjc.mainThread({ () -> () in
                        booleanHandler(success: false)
                    })
                }
                else
                {
                    QwikHttpObjc.mainThread({ () -> () in
                        booleanHandler(success: true)
                    })
                }
            }
        }
    }
    
    //reset our completion handlers and response data
    @objc public func reset()
    {
        self.response = nil
        self.responseString = nil
        self.responseData = nil
        self.responseError = nil
        self.responseData = nil
        booleanHandler = nil
    }
    
    /**** HELPERS ****/
    private func combinedDictionary(from: [String:AnyObject]!, with: [String:AnyObject]! ) -> [String:AnyObject]!
    {
        var result = from
        for(key, value) in with
        {
            result[key] = value
        }
        return result
    }
    
    class func paramStringFrom(from: [String : String]!) -> String!
    {
        var string = ""
        var first = true
        for(key,value) in from
        {
            if !first
            {
                string = string + "&"
            }
            
            if let encoded = value.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            {
                string = string + key + "=" + encoded
            }
            first = false
        }
        return string
    }
    
    private class func mainThread(code: () -> () )
    {
        dispatch_async(dispatch_get_main_queue()) {
            code()
        }
    }
    
    //if we deinit the thread before we ran it, then call an error handler and log this. They probably forgot to send
    deinit
    {

    }
    
}

//this class is used to pool our requests and also to avoid the need to retain our QwikRequest objects
private class HttpRequestPooler
{
    
    private class func paramTypeToString(type: HttpRequestMethod) -> String!
    {
        switch(type)
        {
        case HttpRequestMethod.Post:
            return "POST"
        case HttpRequestMethod.Put:
            return "PUT"
        case HttpRequestMethod.Get:
            return "GET"
        case HttpRequestMethod.Delete:
            return "DELETE"
        }
    }
    
    class func sendRequest(requestParams : QwikHttpObjc!, handler: (NSData?, NSURLResponse?, NSError?) -> Void)
    {
        //make sure our request url is valid
        guard let url = NSURL(string: requestParams.urlString)
            else
        {
            handler(nil,nil,NSError(domain: "QwikHTTP", code: 500, userInfo:["Error" : "Invalid URL"]))
            return
        }
        
        //create our http request
        let request = NSMutableURLRequest(URL: url, cachePolicy: requestParams.cachePolicy, timeoutInterval: requestParams.timeOut)
        
        //set up our http method and add headers
        request.HTTPMethod = paramTypeToString(requestParams.httpMethod)
        for(key, value) in requestParams.headers
        {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        //set up our parameters
        if let body = requestParams.body
        {
            request.HTTPBody = body
        }
        else if requestParams.parameterType == .FormEncoded  && requestParams.params.count > 0
        {
            //convert parameters to form encoded values and set to body
            if let params = requestParams.params as? [String : String]
            {
                request.HTTPBody = QwikHttp.paramStringFrom(params).dataUsingEncoding(NSUTF8StringEncoding)
                
                //set the request type headers
                //application/x-www-form-urlencoded
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            }
                
                //if we couldn't encode the values, then perhaps json was passed in unexpectedly, so try to parse it as json.
            else
            {
                requestParams.setParameterType(.Json)
            }
        }
        
        //try json parsing, note that formEncoding could have changed the type if there was an error, so don't use an else if
        if requestParams.parameterType == .Json && requestParams.params.count > 0
        {
            //convert parameters to json string and form and set to body
            do {
                let data = try NSJSONSerialization.dataWithJSONObject(requestParams.params, options: NSJSONWritingOptions(rawValue: 0))
                request.HTTPBody = data
            }
            catch let JSONError as NSError {
                handler(nil,nil,JSONError)
                return
            }
            
            //set the request type headers
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        //show our spinner
        var showingSpinner = false
        if let title = requestParams.loadingTitle
        {
            SwiftSpinner.show(title)
            showingSpinner = true
        }
        
        //send our request and do a bunch of common stuff before calling our response handler
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (responseData, urlResponse, error) -> Void in
            
            //set the values straight to the request object so we can read it if needed.
            requestParams.responseData = responseData
            requestParams.responseError = error

            //set our response string
            if let responseString = self.getResponseString(responseData)
            {
                requestParams.responseString = responseString
            }
            
            //hide our spinner
            if showingSpinner
            {
                SwiftSpinner.hide()
            }
            
            //check the responseCode to make sure its valid
            if let httpResponse = urlResponse as? NSHTTPURLResponse {
            
                requestParams.response = httpResponse
            
                if httpResponse.statusCode != 200 && error == nil
                {
                    handler(responseData, urlResponse, NSError(domain: "QwikHttp", code: httpResponse.statusCode, userInfo: ["Error": "Error Response Code"]))
                    return
                }
            }
            
            handler(responseData, urlResponse, error)
        })
        
        task.resume()
    }
    
    //a helper to to return an optional string from our ns data
    class func getResponseString(data : NSData?) -> String?
    {
        if let d = data{
            return String(data: d, encoding: NSUTF8StringEncoding)
        }
        else
        {
            return nil
        }
    }
    
}


        


