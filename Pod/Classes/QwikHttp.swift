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

public typealias BooleanCompletionHandler = (success: Bool) -> Void

/****** REQUEST TYPES *******/
public enum HttpRequestMethod : String {
    case get = "GET", post = "POST", delete = "DELETE", put = "PUT"
}

//parameter types
public enum ParameterType : String
{
    case json = "JSON", formEncoded = "FORM"
}

//a class to store default values
public class QwikHttpDefaults
{
    private static var defaultTimeOut = 40 as Double
    private static var defaultCachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
    private static var defaultParameterType = ParameterType.json
    private static var defaultLoadingTitle : String? = nil
    
    public class func setDefaultTimeOut(timeout: Double!)
    {
        if(timeout > 0)
        {
            defaultTimeOut = timeout
        }
    }
    
    public class func setDefaultLoadingTitle(title: String?)
    {
        defaultLoadingTitle = title
    }
    public class func setDefaultCachePolicy(policy: NSURLRequestCachePolicy!)
    {
        defaultCachePolicy = policy
    }
    public class func setDefaultParameterType(type: ParameterType!)
    {
        defaultParameterType = type
    }
}

//the main request object
public class QwikHttp<T : QwikDataConversion> {
    
    public typealias ResponseHandler = (T?, NSError?, QwikHttp!) -> Void
    public typealias ArrayResponseHandler = ([T]?, NSError?, QwikHttp!) -> Void
    
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
    private var sent = false
    
    //handlers
    private var genericHandler : ResponseHandler?
    private var genericArrayHandler : ArrayResponseHandler?
    private var booleanHandler : BooleanCompletionHandler?
    
    //class params
    private var timeOut : Double!
    private var cachePolicy: NSURLRequestCachePolicy!
    private var loadingTitle: String?
    
    /**** REQUIRED INITIALIZER*****/
    public init(urlString: String!, httpMethod: HttpRequestMethod!)
    {
        self.urlString = urlString
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
    public func addParam(key : String!, value: String!) -> QwikHttp
    {
        params[key] = value
        return self
    }
    public func addHeader(key : String!, value: String!) -> QwikHttp
    {
        headers[key] = value
        return self
    }
    
    public func setLoadingTitle(title: String?) -> QwikHttp
    {
        self.loadingTitle = title
        return self
    }
    
    public func addUrlParams(params: [String: String]!) -> QwikHttp
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
    
    public func setObject(object: QwikJson?)  -> QwikHttp
    {
        if let qwikJson = object,  params = qwikJson.toDictionary() as? [String : AnyObject]
        {
            self.addParams(params)
            self.setParameterType(.json)
        }
        return self
    }
    
    public func setObjects<Q : QwikJson>(objects: [Q]?, toModelClass modelClass: Q.Type)  -> QwikHttp
    {
        if let array = objects, params = QwikJson.jsonArrayFromArray(array, ofClass: modelClass )
        {
            do{
                let data = try NSJSONSerialization.dataWithJSONObject(params, options: .PrettyPrinted)
                self.setBody(data)
                self.addHeader("Content-Type", value: "application/json")
            }
            catch _ as NSError {}
        }
        return self
    }
    
    public func addParams(params: [String: AnyObject]!) -> QwikHttp
    {
        self.params = combinedDictionary(self.params, with: params)
        return self
    }
    
    public func addHeaders(headers: [String: String]!) -> QwikHttp
    {
        self.headers = combinedDictionary(self.headers, with: headers) as! [String : String]
        return self
    }
    public func setBody(body : NSData!) -> QwikHttp
    {
        self.body = body
        return self;
    }
    public func setParameterType(parameterType : ParameterType!) -> QwikHttp
    {
        self.parameterType = parameterType
        return self;
    }
    
    public func setCachePolicy(policy: NSURLRequestCachePolicy!) -> QwikHttp
    {
        cachePolicy = policy
        return self
    }
    public func setTimeOut(timeOut: Double!) -> QwikHttp
    {
        self.timeOut = timeOut
        return self
    }
    
    /********* RESPONSE HANDLERS / SENDING METHODS *************/
    
    
    public func getResponse(handler : ResponseHandler!)
    {
        genericHandler = handler;
        self.send()
    }
    
    public func getArrayResponse(handler : ArrayResponseHandler!)
    {
        genericArrayHandler = handler;
        self.send()
    }
    
    //Send the request!
    public func send(handler: BooleanCompletionHandler? = nil)
    {
        self.booleanHandler = handler
        
        //if we haven't sent the
        if(!sent)
        {
            self.sent = true
            HttpRequestPooler.sendRequest(self)
        }
        else
        {
            let error = NSError(domain: "QwikHttp", code: 0, userInfo: ["Error" : "This request has already been sent. You must reset it before sending again"])
            
            //call completion handler with an error
            if let objectHandler = self.genericHandler
            {
                objectHandler(T.fromData(self.responseData),error,self)
            }
            else if let arrayHandler = self.genericArrayHandler
            {
                arrayHandler(T.arrayFromData(self.responseData),error,self)
            }else if let booleanHandler = self.booleanHandler
            {
                //if we are using the boolean handler, then we called the send
                booleanHandler(success: false)
            }
        }
    }
    
    //reset our completion handlers and response data
    public func reset()
    {
        self.response = nil
        self.responseString = nil
        self.responseData = nil
        self.responseError = nil
        self.responseData = nil
        self.sent = false
        genericHandler = nil
        genericArrayHandler = nil
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
    
    //if we deinit the thread before we ran it, then call an error handler and log this. They probably forgot to send
    deinit
    {
        if(!self.sent)
        {
            NSLog("QwikHttp Error: Request to URL %@ dealloc'ed before it was sent. You likely forgot to call send() or need to add a strong reference to the object.",urlString)
        }
    }
    
}

//this class is used to pool our requests and also to avoid the need to retain our QwikRequest objects
private class HttpRequestPooler<T : QwikDataConversion>
{
    class func sendRequest(requestParams : QwikHttp<T>!)
    {
        //make sure our request url is valid
        guard let url = NSURL(string: requestParams.urlString)
            else
        {
            didError(requestParams, error: nil, message: "Invalid URL")
            return
        }
        
        //create our http request
        let request = NSMutableURLRequest(URL: url, cachePolicy: requestParams.cachePolicy, timeoutInterval: requestParams.timeOut)
        
        //set up our http method and add headers
        request.HTTPMethod = requestParams.httpMethod.rawValue
        for(key, value) in requestParams.headers
        {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        //set up our parameters
        if let body = requestParams.body
        {
            request.HTTPBody = body
        }
        else if requestParams.parameterType == .formEncoded  && requestParams.params.count > 0
        {
            //convert parameters to form encoded values and set to body
            if let params = requestParams.params as? [String : String]
            {
                request.HTTPBody = QwikHttp<T>.paramStringFrom(params).dataUsingEncoding(NSUTF8StringEncoding)
                
                //set the request type headers
                //application/x-www-form-urlencoded
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            }
                
                //if we couldn't encode the values, then perhaps json was passed in unexpectedly, so try to parse it as json.
            else
            {
                requestParams.setParameterType(.json)
            }
        }
        
        //try json parsing, note that formEncoding could have changed the type if there was an error, so don't use an else if
        if requestParams.parameterType == .json && requestParams.params.count > 0
        {
            //convert parameters to json string and form and set to body
            do {
                let data = try NSJSONSerialization.dataWithJSONObject(requestParams.params, options: NSJSONWritingOptions(rawValue: 0))
                request.HTTPBody = data
            }
            catch let JSONError as NSError {
                didError(requestParams, error: JSONError, message: "Could not serialize Params to JSON")
                return
            }
            
            //set the request type headers
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        var showingSpinner = false
        if let title = requestParams.loadingTitle
        {
            SwiftSpinner.show(title)
            showingSpinner = true
        }
        
        //send our request
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (responseData, urlResponse, error) -> Void in
            
            //set the values straight to the request object so we can read it if needed.
            requestParams.responseData = responseData
            requestParams.responseError = error
            
            if let responseString = self.getResponseString(responseData)
            {
                requestParams.responseString = responseString
            }
            
            if showingSpinner
            {
                SwiftSpinner.hide()
            }
            
            //set the responseCode
            if let httpResponse = urlResponse as? NSHTTPURLResponse {
                
                requestParams.response = httpResponse
                
                if httpResponse.statusCode != 200
                {
                    didError(requestParams, error: nil, message: "Reponse Code: " )
                    return
                }
            }
            
            //if we have an error and an error handler, call the error handler.
            if let e = error
            {
                didError(requestParams, error: e, message: nil)
                return
            }
                
            //otherwise try to parse our response data into the corresponding types for our completion handlers
            else if let objectHandler = requestParams.genericHandler
            {
                if let response = result(responseData)
                {
                    self.mainThread({ () -> () in
                      objectHandler(response, nil, requestParams)
                        if let boolHandler = requestParams.booleanHandler
                        {
                            boolHandler(success: true)
                        }
                    })
                }
                else
                {
                    didError(requestParams, error: nil, message: "Unable to parse response")
                }
            }
            else if let arrayHandler = requestParams.genericArrayHandler
            {
                if let response = arrayResult(responseData)
                {
                    self.mainThread({ () -> () in
                        arrayHandler(response, nil, requestParams)
                        if let boolHandler = requestParams.booleanHandler
                        {
                            boolHandler(success: true)
                        }
                    })
                }
                else
                {
                    didError(requestParams, error: nil, message: "Unable to parse response")
                }
            }
            else
            {
                //no error, no databack.
                if let objectHandler = requestParams.genericHandler
                {
                    self.mainThread({ () -> () in
                        objectHandler( nil, nil, requestParams)
                    })
                }
                //no error, no databack.
                if let arrayHandler = requestParams.genericArrayHandler
                {
                    self.mainThread({ () -> () in
                        arrayHandler(nil, nil, requestParams)
                    })
                }
                if let boolHandler = requestParams.booleanHandler
                {
                    self.mainThread({ () -> () in
                        boolHandler(success: true)
                    })
                }
            }
        })
        
        task.resume()
    }
    
    class func result(from : NSData?) -> T?
    {
        return T.fromData(from)
    }
    
    class func arrayResult(from : NSData?) -> [T]?
    {
        return T.arrayFromData(from)
    }
    
    private class func mainThread(code: () -> () )
    {
        dispatch_async(dispatch_get_main_queue()) {
            code()
        }
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
    
    class func didError<T>(params: QwikHttp<T>!, error:NSError?, message: String?)
    {
        if let respError = error{
            params.responseError = respError
        }else if let errorMessage = message
        {
            params.responseError = NSError(domain: "QwikHTTP", code: 0, userInfo: ["Error" : errorMessage])
        }
        
        mainThread({ () -> () in
            //no error, no databack.
            if let objectHandler = params.genericHandler
            {
                objectHandler( nil, params.responseError, params)
            }
            //no error, no databack.
            if let arrayHandler = params.genericArrayHandler
            {
                arrayHandler(nil, params.responseError, params)
            }
            if let boolHandler = params.booleanHandler
            {
                boolHandler(success: false)
            }
        })
    }
}


        


