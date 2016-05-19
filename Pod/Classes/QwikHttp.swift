//
//  QwikHttp.swift
//  oAuthExample
//
//  Created by Logan Sease on 1/26/16.
//  Copyright © 2016 Logan Sease. All rights reserved.
//

import Foundation
import QwikJson

public typealias BooleanCompletionHandler = (success: Bool) -> Void

/****** REQUEST TYPES *******/
@objc public enum HttpRequestMethod : Int {
    case Get = 0, Post, Put, Delete
}

//parameter types
@objc public enum ParameterType : Int
{
    case Json = 0, FormEncoded
}

//indicates if the response should be called on the background or main thread
@objc public enum ResponseThread : Int
{
    case Main = 0, Background
}

//a delegate used to configure and show a custom loading indicator.
@objc public protocol QwikHttpLoadingIndicatorDelegate
{
    @objc func showIndicator(title: String!)
    @objc func hideIndicator()
}


//This interceptor protocol is in place so that we can register an interceptor to our class to intercept certain
//responses. This could be useful to check for expired tokens and then retry the request instead of calling the
//handler with the error. This could also allow you to show the login screen when an unautorized response is returned
//using this class will help avoid the need to do this constantly on each api call.
public protocol QwikHttpResponseInterceptor
{
     func shouldInterceptResponse(response: NSURLResponse!) -> Bool
     func interceptResponse(request : QwikHttp!, handler: (NSData?, NSURLResponse?, NSError?) -> Void)
}

//the request interceptor can be used to intercept requests before they are sent out.
public protocol QwikHttpRequestInterceptor
{
    func shouldInterceptRequest(request: QwikHttp!) -> Bool
    func interceptRequest(request : QwikHttp!,  handler: (NSData?, NSURLResponse?, NSError?) -> Void)
}


//a class to store default values and configuration for quikHttp
@objc public class QwikHttpConfig : NSObject
{
    public private(set) static var defaultTimeOut = 40 as Double
    public static var defaultCachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
    public static var defaultParameterType = ParameterType.Json
    public static var defaultLoadingTitle : String? = nil
    public static var loadingIndicatorDelegate: QwikHttpLoadingIndicatorDelegate? = nil
    public static var responseInterceptor: QwikHttpResponseInterceptor? = nil
    public static var responseInterceptorObjc: QwikHttpObjcResponseInterceptor? = nil
    public static var requestInterceptor: QwikHttpRequestInterceptor? = nil
    public static var requestInterceptorObjc: QwikHttpObjcRequestInterceptor? = nil
    public static var defaultResponseThread : ResponseThread = .Main
    
    //ensure timeout > 0
    public class func setDefaultTimeOut(timeout: Double!)
    {
        if(timeout > 0)
        {
            defaultTimeOut = timeout
        }
        else
        {
            defaultTimeOut = 40
        }
    }
}

//the main request object
public class QwikHttp {
    
    /***** REQUEST VARIABLES ******/
    private var urlString : String!
    private var httpMethod : HttpRequestMethod!
    private var headers : [String : String]!
    private var params : [String : AnyObject]!
    private var body: NSData?
    private var parameterType : ParameterType!
    private var responseThread : ResponseThread!
    
    //response variables
    public var responseError : NSError?
    public var responseData : NSData?
    public var response: NSURLResponse?
    public var responseString : NSString?
    public var wasIntercepted = false
    
    //class params
    private var timeOut : Double!
    private var cachePolicy: NSURLRequestCachePolicy!
    private var loadingTitle: String?
    
    /**** REQUIRED INITIALIZER*****/
    public convenience init(url: String!, httpMethod: HttpRequestMethod!)
    {
        self.init(url,httpMethod: httpMethod)
    }
    
    public init(_ url: String!, httpMethod: HttpRequestMethod!)
    {
        self.urlString = url
        self.httpMethod = httpMethod
        self.headers = [:]
        self.params = [:]
        
        //set defaults
        self.parameterType = QwikHttpConfig.defaultParameterType
        self.cachePolicy = QwikHttpConfig.defaultCachePolicy
        self.timeOut = QwikHttpConfig.defaultTimeOut
        self.loadingTitle = QwikHttpConfig.defaultLoadingTitle
        self.responseThread = QwikHttpConfig.defaultResponseThread
    }
    
    /**** ADD / SET VARIABLES. ALL RETURN SELF TO ENCOURAGE SINGLE LINE BUILDER TYPE SYNTAX *****/
    
    //add a parameter to the request
    public func addParam(key : String!, value: String?) -> QwikHttp
    {
        if let v = value
        {
            params[key] = v
        }
        
        return self
    }
    
    //add a header
    public func addHeader(key : String!, value: String?) -> QwikHttp
    {
        if let v = value
        {
            headers[key] = v
        }
        return self
    }
    
    //set a title to the loading indicator. Set to nil for no indicator
    public func setLoadingTitle(title: String?) -> QwikHttp
    {
        self.loadingTitle = title
        return self
    }
    
    //add a single optional URL parameter
    public func addUrlParam(key: String!, value: String?) -> QwikHttp
    {
        guard let param = value else
        {
            return self
        }
        
        //start our URL Parameters
        if let _ = urlString.rangeOfString("?")
        {
            urlString = urlString + "&"
        }
        else
        {
            urlString = urlString + "?"
        }
        
        urlString = urlString + QwikHttp.paramStringFrom([key : param])
        return self
    }
    
    
    //add an array of URL parameters
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
    
    public func removeUrlParam(key: String!)
    {
        //get our query items from the url
        if #available(OSX 10.10, *)
        {
            if let urlComponents = NSURLComponents(string: urlString), items = urlComponents.queryItems
            {
                //get a new array of query items by removing any with the key we want
                let newItems = items.filter { $0.name == key }
                
                //reconstruct our url if we removed anything
                if(newItems.count != items.count)
                {
                    urlComponents.queryItems = newItems
                    urlString = urlComponents.string
                }
            }
        }
    }
    
    //set a quikJson into the request. Will serialize to json and set the content type.
    public func setObject(object: QwikJson?)  -> QwikHttp
    {
        if let qwikJson = object,  params = qwikJson.toDictionary() as? [String : AnyObject]
        {
            self.addParams(params)
            self.setParameterType(.Json)
        }
        return self
    }
    
    //set an array of objects to the request body serialized as json objects.
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
    
    //add an list of parameters
    public func addParams(params: [String: AnyObject]!) -> QwikHttp
    {
        self.params = combinedDictionary(self.params, with: params)
        return self
    }
    
    //add a list of headers
    public func addHeaders(headers: [String: String]!) -> QwikHttp
    {
        self.headers = combinedDictionary(self.headers, with: headers) as! [String : String]
        return self
    }
    
    //set the body directly
    public func setBody(body : NSData!) -> QwikHttp
    {
        self.body = body
        return self;
    }
    
    //set the parameter type
    public func setParameterType(parameterType : ParameterType!) -> QwikHttp
    {
        self.parameterType = parameterType
        return self;
    }
    
    //set the cache policy
    public func setCachePolicy(policy: NSURLRequestCachePolicy!) -> QwikHttp
    {
        cachePolicy = policy
        return self
    }
    
    //set the request time out
    public func setTimeOut(timeOut: Double!) -> QwikHttp
    {
        self.timeOut = timeOut
        return self
    }
    public func setResponseThread(responseThread: ResponseThread!) -> QwikHttp
    {
        self.responseThread = responseThread
        return self
    }
    
    /********* RESPONSE HANDLERS / SENDING METHODS *************/
    
    //get an an object of a generic type back
    public func getResponse<T : QwikDataConversion>(type: T.Type, _ handler :  (T?, NSError?, QwikHttp!) -> Void)
    {
        HttpRequestPooler.sendRequest(self) { (data, response, error) -> Void in
            
            //check for an error
            if let e = error
            {
                self.determineThread({ () -> () in
                    handler(nil,e, self)
                })
            }
            else
            {
                //try to deserialize our object
                if let t : T = T.fromData(data)
                {
                    self.determineThread({ () -> () in
                        handler(t,nil,self)
                    })
                }
                    
                    //error if we could deserialize
                else
                {
                    self.determineThread({ () -> () in
                        handler(nil,NSError(domain: "QwikHttp", code: 500, userInfo: ["Error" : "Could not parse response"]), self)
                    })
                }
            }
        }
    }
    
    //get an array of a generic type back
    public func getArrayResponse<T : QwikDataConversion>(type: T.Type, _ handler :  ([T]?, NSError?, QwikHttp!) -> Void)
    {
        HttpRequestPooler.sendRequest(self) { (data, response, error) -> Void in
            
            //check for error
            if let e = error
            {
                self.determineThread({ () -> () in
                    handler(nil,e, self)
                })
            }
            else
            {
                //convert the response to an array of T
                if let t : [T] = T.arrayFromData(data)
                {
                    self.determineThread({ () -> () in
                        handler(t,nil,self)
                    })
                }
                else
                {
                    //error if we could not deserialize
                    self.determineThread({ () -> () in
                        handler(nil,NSError(domain: "QwikHttp", code: 500, userInfo: ["Error" : "Could not parse response"]), self)
                    })
                }
            }
        }
    }
    
    //Send the request with a simple boolean handler, which is optional
    public func send( handler: BooleanCompletionHandler? = nil)
    {
        HttpRequestPooler.sendRequest(self) { (data, response, error) -> Void in
            
            if let booleanHandler = handler
            {
                if let _ = error
                {
                    self.determineThread({ () -> () in
                        booleanHandler(success: false)
                    })
                }
                else
                {
                    self.determineThread({ () -> () in
                        booleanHandler(success: true)
                    })
                }
            }
        }
    }

    //this method is primarily used for the response interceptor as any easy way to restart the request
    public func resend(handler: (NSData?,NSURLResponse?, NSError? ) -> Void)
    {
        HttpRequestPooler.sendRequest(self, handler: handler)
    }
    
    //reset our completion handlers and response data
    public func reset()
    {
        self.response = nil
        self.responseString = nil
        self.responseData = nil
        self.responseError = nil
        self.responseData = nil
        self.wasIntercepted = false
    }
    
    /**** HELPERS ****/
    
    //combine two dictionaries
    private func combinedDictionary(from: [String:AnyObject]!, with: [String:AnyObject]! ) -> [String:AnyObject]!
    {
        var result = from
        for(key, value) in with
        {
            result[key] = value
        }
        return result
    }
    
    //create a url parameter string
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
    
    //determine if we should run on the main or background thread and run it conditionally
    private func determineThread(code: () -> () )
    {
        if(self.responseThread == .Main)
        {
            dispatch_async(dispatch_get_main_queue()) {
                code()
            }
        }
        else
        {
            code()
        }
    }
    
    //run on the main thread
    private class func mainThread(code: () -> () )
    {
        dispatch_async(dispatch_get_main_queue()) {
            code()
        }
    }
    
}

//this class is used to pool our requests and also to avoid the need to retain our QwikRequest objects
private class HttpRequestPooler
{
    class func sendRequest(requestParams : QwikHttp!, handler: (NSData?, NSURLResponse?, NSError?) -> Void)
    {
        //make sure our request url is valid
        guard let url = NSURL(string: requestParams.urlString)
            else
        {
            handler(nil,nil,NSError(domain: "QwikHTTP", code: 500, userInfo:["Error" : "Invalid URL"]))
            return
        }
        
        //see if this request should be intercepted and if so call the interceptor.
        //don't worry about a completion handler since this should be called by the interceptor
        if let interceptor = QwikHttpConfig.requestInterceptor where interceptor.shouldInterceptRequest(requestParams) && !requestParams.wasIntercepted
        {
            requestParams.wasIntercepted = true
            interceptor.interceptRequest(requestParams, handler: handler)
            return
        }
        
        //create our http request
        let request = NSMutableURLRequest(URL: url, cachePolicy: requestParams.cachePolicy, timeoutInterval: requestParams.timeOut)
        
        //set up our http method and add headers
        request.HTTPMethod = HttpRequestPooler.paramTypeToString(requestParams.httpMethod)
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
        if let title = requestParams.loadingTitle, indicatorDelegate = QwikHttpConfig.loadingIndicatorDelegate
        {
            indicatorDelegate.showIndicator(title)
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
            if let indicatorDelegate = QwikHttpConfig.loadingIndicatorDelegate where showingSpinner == true
            {
                indicatorDelegate.hideIndicator()
            }
            
            //check the responseCode to make sure its valid
            if let httpResponse = urlResponse as? NSHTTPURLResponse {
                
                requestParams.response = httpResponse
                
                //see if we are configured to use an interceptor and if so, check it to see if we should use it
                if let interceptor = QwikHttpConfig.responseInterceptor where !requestParams.wasIntercepted &&  interceptor.shouldInterceptResponse(httpResponse)
                {
                    //call the interceptor and return. The interceptor will call our handler.
                    requestParams.wasIntercepted = true
                    interceptor.interceptResponse(requestParams, handler: handler)
                    return
                }
                
                //error for invalid response
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
    
    //convert our enum to a string used for the request
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


        


