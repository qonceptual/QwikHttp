//
//  QwikHttp.swift
//  oAuthExample
//
//  Created by Logan Sease on 1/26/16.
//  Copyright © 2016 Logan Sease. All rights reserved.
//

import Foundation
import QwikJson

public typealias QBooleanCompletionHandler = (_ success: Bool) -> Void

/****** REQUEST TYPES *******/
@objc public enum HttpRequestMethod : Int {
    case get = 0, post, put, delete, patch
}

//parameter types
@objc public enum ParameterType : Int
{
    case json = 0, formEncoded
}

//parameter types
@objc public enum QwikHttpLoggingLevel : Int
{
    case none = 0, errors, requests, debug
}

//indicates if the response should be called on the background or main thread
@objc public enum ResponseThread : Int
{
    case main = 0, background
}

//a delegate used to configure and show a custom loading indicator.
@objc public protocol QwikHttpLoadingIndicatorDelegate
{
    @objc func showIndicator(_ title: String!)
    @objc func hideIndicator()
}


//This interceptor protocol is in place so that we can register an interceptor to our class to intercept certain
//responses. This could be useful to check for expired tokens and then retry the request instead of calling the
//handler with the error. This could also allow you to show the login screen when an unautorized response is returned
//using this class will help avoid the need to do this constantly on each api call.
@objc public protocol QwikHttpResponseInterceptor
{
     @objc optional func didSend(_ request: QwikHttp!)
     func shouldInterceptResponse(_ response: URLResponse!) -> Bool
     func interceptResponse(_ request : QwikHttp!, handler: @escaping (Data?, URLResponse?, NSError?) -> Void)
}

//the request interceptor can be used to intercept requests before they are sent out.
@objc public protocol QwikHttpRequestInterceptor
{
    func shouldInterceptRequest(_ request: QwikHttp!) -> Bool
    func interceptRequest(_ request : QwikHttp!,  handler: @escaping (Data?, URLResponse?, NSError?) -> Void)
}


//a class to store default values and configuration for quikHttp
@objc public class QwikHttpConfig : NSObject
{
    open fileprivate(set) static var defaultTimeOut = 40 as Double
    open static var defaultCachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
    open static var defaultParameterType = ParameterType.json
    open static var defaultLoadingTitle : String? = nil
    open static var loadingIndicatorDelegate: QwikHttpLoadingIndicatorDelegate? = nil
    
    open static var responseInterceptor: QwikHttpResponseInterceptor? = nil
    open static var requestInterceptor: QwikHttpRequestInterceptor? = nil
    open static var standardHeaders : [String : String]! = [:]
    open static var loggingLevel : QwikHttpLoggingLevel = .errors
    
//    @objc public static var responseInterceptorObjc: QwikHttpObjcResponseInterceptor? = nil
//    @objc public static var requestInterceptorObjc: QwikHttpObjcRequestInterceptor? = nil
    
    open static var defaultResponseThread : ResponseThread = .main
    
    //ensure timeout > 0
    open class func setDefaultTimeOut(_ timeout: Double!)
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
@objc open class QwikHttp : NSObject {
    
    /***** REQUEST VARIABLES ******/
    fileprivate var urlString : String!
    fileprivate var httpMethod : HttpRequestMethod!
    fileprivate var headers : [String : String]!
    fileprivate var params : [String : AnyObject]!
    fileprivate var body: Data?
    fileprivate var parameterType : ParameterType!
    fileprivate var responseThread : ResponseThread!
    fileprivate var avoidResponseInterceptor = false
    fileprivate var avoidRequestInterceptor = false
    fileprivate var avoidStandardHeaders : Bool = false
    
    //response variables
    open var responseError : NSError?
    open var responseData : Data?
    open var response: URLResponse?
    open var responseString : NSString?
    open var wasIntercepted = false
    open var responseStatusCode : Int = 0
    
    
    //class params
    fileprivate var timeOut : Double!
    fileprivate var cachePolicy: URLRequest.CachePolicy!
    fileprivate var loadingTitle: String?
    
    /**** REQUIRED INITIALIZER*****/
    @objc public convenience init(url: String!, httpMethod: HttpRequestMethod)
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
        self.parameterType = QwikHttpConfig.defaultParameterType
        self.cachePolicy = QwikHttpConfig.defaultCachePolicy
        self.timeOut = QwikHttpConfig.defaultTimeOut
        self.loadingTitle = QwikHttpConfig.defaultLoadingTitle
        self.responseThread = QwikHttpConfig.defaultResponseThread
    }
    
    /**** ADD / SET VARIABLES. ALL RETURN SELF TO ENCOURAGE SINGLE LINE BUILDER TYPE SYNTAX *****/
    
    //add a parameter to the request
    @objc open func addParam(_ key : String!, value: String?) -> QwikHttp
    {
        if let v = value
        {
            params[key] = v as AnyObject?
        }
        
        return self
    }
    
    //add a header
    @objc open func addHeader(_ key : String!, value: String?) -> QwikHttp
    {
        if let v = value
        {
            headers[key] = v
        }
        return self
    }
    
    //set a title to the loading indicator. Set to nil for no indicator
    @objc open func setLoadingTitle(_ title: String?) -> QwikHttp
    {
        self.loadingTitle = title
        return self
    }
    
    //add a single optional URL parameter
    @objc open func addUrlParam(_ key: String!, value: String?) -> QwikHttp
    {
        guard let param = value else
        {
            return self
        }
        
        //start our URL Parameters
        if let _ = urlString.range(of: "?")
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
    @objc open func addUrlParams(_ params: [String: String]!) -> QwikHttp
    {
        //start our URL Parameters
        if let _ = urlString.range(of: "?")
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
    
    @objc open func removeUrlParam(_ key: String!)
    {
        //get our query items from the url
        if #available(OSX 10.10, *)
        {
            if var urlComponents = URLComponents(string: urlString), let items = urlComponents.queryItems
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
    @objc open func setObject(_ object: QwikJson?)  -> QwikHttp
    {
        if let qwikJson = object,  let params = qwikJson.toDictionary() as? [String : AnyObject]
        {
            _ = self.addParams(params)
            _ = self.setParameterType(.json)
        }
        return self
    }
    
    //set an array of objects to the request body serialized as json objects.
    open func setObjects<Q : QwikJson>(_ objects: [Q]?, toModelClass modelClass: Q.Type)  -> QwikHttp
    {
        if let array = objects, let params = QwikJson.jsonArray(from: array, of: modelClass )
        {
            do{
                let data = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                _ = self.setBody(data)
                _ = self.addHeader("Content-Type", value: "application/json")
            }
            catch _ as NSError {}
        }
        return self
    }
    
    //add an list of parameters
    @objc open func addParams(_ params: [String: AnyObject]!) -> QwikHttp
    {
        self.params = combinedDictionary(self.params, with: params)
        return self
    }
    
    //add a list of headers
    @objc open func addHeaders(_ headers: [String: String]!) -> QwikHttp
    {
        self.headers = combinedDictionary(self.headers as [String : AnyObject]!, with: headers as [String : AnyObject]!) as! [String : String]
        return self
    }
    
    //set the body directly
    @objc open func setBody(_ body : Data!) -> QwikHttp
    {
        self.body = body
        return self;
    }
    
    //get the body as a string for debugging purposes, very useful for displaying the json after the request is sent
    @objc open func getBody() -> String?
    {
        guard let data = self.body else
        {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    //set the parameter type
    @objc open func setParameterType(_ parameterType : ParameterType) -> QwikHttp
    {
        self.parameterType = parameterType
        return self;
    }
    
    //set the cache policy
    @objc open func setCachePolicy(_ policy: URLRequest.CachePolicy) -> QwikHttp
    {
        cachePolicy = policy
        return self
    }
    
    //do not add standard headers if this is set to true
    @objc open func setAvoidStandardHeaders(_ avoid: Bool) -> QwikHttp
    {
        self.avoidStandardHeaders = avoid
        return self
    }
    
    //set the request time out
    @objc open func setTimeOut(_ timeOut: Double) -> QwikHttp
    {
        self.timeOut = timeOut
        return self
    }
    @objc open func setResponseThread(_ responseThread: ResponseThread) -> QwikHttp
    {
        self.responseThread = responseThread
        return self
    }
    
    /********* RESPONSE HANDLERS / SENDING METHODS *************/
    
    //get an an object of a generic type back
    open func getResponse<T : QwikDataConversion>(_ type: T.Type, _ handler :  @escaping (T?, NSError?, QwikHttp) -> Void)
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
    open func getArrayResponse<T : QwikDataConversion>(_ type: T.Type, _ handler :  @escaping ([T]?, NSError?, QwikHttp) -> Void)
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
    @objc open func send( _ handler: QBooleanCompletionHandler? = nil)
    {
        HttpRequestPooler.sendRequest(self) { (data, response, error) -> Void in
            
            if let booleanHandler = handler
            {
                if let _ = error
                {
                    self.determineThread({ () -> () in
                        booleanHandler(false)
                    })
                }
                else
                {
                    self.determineThread({ () -> () in
                        booleanHandler(true)
                    })
                }
            }
        }
    }
    
    //a helper method to duck the response interceptor. Can be useful for cases like logout which
    //could lead to infinite recursion
    @objc open func setAvoidResponseInterceptor(_ avoid : Bool)  -> QwikHttp!
    {
        self.avoidResponseInterceptor = true
        return self
    }
    
    //a helper method to duck the request interceptor. Can be useful for cases like token refresh which
    //could lead to infinite recursion
    @objc open func setAvoidRequestInterceptor(_ avoid : Bool)  -> QwikHttp!
    {
        self.avoidRequestInterceptor = true
        return self
    }

    //this method is primarily used for the response interceptor as any easy way to restart the request
    @objc open func resend(_ handler: @escaping (Data?,URLResponse?, NSError? ) -> Void)
    {
        HttpRequestPooler.sendRequest(self, handler: handler)
    }
    
    //reset our completion handlers and response data
    @objc open func reset()
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
    fileprivate func combinedDictionary(_ from: [String:AnyObject]!, with: [String:AnyObject]! ) -> [String:AnyObject]!
    {
        var result = from

        //ensure someone didn't pass us nil on accident
        if(with == nil)
        {
            return result
        }
        
        for(key, value) in with
        {
            result?[key] = value
        }
        return result
    }
    
    //create a url parameter string
    class func paramStringFrom(_ from: [String : String]!) -> String!
    {
        var string = ""
        var first = true
        for(key,value) in from
        {
            if !first
            {
                string = string + "&"
            }
            
            if let encoded = value.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            {
                string = string + key + "=" + encoded
            }
            first = false
        }
        return string
    }
    
    //determine if we should run on the main or background thread and run it conditionally
    fileprivate func determineThread(_ code: @escaping () -> () )
    {
        if(self.responseThread == .main)
        {
            DispatchQueue.main.async {
                code()
            }
        }
        else
        {
            code()
        }
    }
    
    //run on the main thread
    fileprivate class func mainThread(_ code: @escaping () -> () )
    {
        DispatchQueue.main.async {
            code()
        }
    }
    
    @objc open func printDebugInfo(excludeResponse : Bool = false)
    {
        NSLog("%@",debugInfo(excludeResponse: excludeResponse))
    }
    
    @objc open func debugInfo(excludeResponse : Bool = false) -> String
    {
        var log = "----- QwikHttp Request -----\n"
        log = log + String(format: "%@ to %@\n", HttpRequestPooler.paramTypeToString(self.httpMethod), self.urlString)
        log = log + "HEADERS:\n"
        for (key, value) in self.headers
        {
            log = log + String(format: "%@: %@\n", key, value)
        }
        
        log = log + "BODY:\n"
        if let body = self.getBody()
        {
            log = log + String(format: "%@\n", body)
        }
        
        if excludeResponse == false
        {
            log = log + String(format: "RESPONSE: %@\n", String(self.responseStatusCode))
            if let responseData = self.responseData, let responseString = String(data: responseData, encoding: .utf8)
            {
                log = log + responseString + "\n"
            }
            if let error = responseError
            {
                log = log + String(format: "ERROR: %@\n",error.debugDescription)
            }
        }
        return log
    }
}

extension QwikHttp
{
    @objc open func getStringResponse(_ handler :  @escaping (String?, NSError?, QwikHttp) -> Void)
    {
        HttpRequestPooler.sendRequest(self) { (data, response, error) -> Void in
            
            if let e = error
            {
                self.determineThread({ () -> () in
                    handler(nil,e, self)
                })
            }
            else
            {
                if let t : String = String.fromData(data)
                {
                    self.determineThread({ () -> () in
                        handler(t,nil,self)
                    })
                }
            }
        }
    }
    
    @objc open func getDataResponse(_ handler :  @escaping (Data?, NSError?, QwikHttp) -> Void)
    {
        HttpRequestPooler.sendRequest(self) { (data, response, error) -> Void in
            
            self.determineThread({ () -> () in
                handler(data,error, self)
            })
        }
    }
    
    @objc open func getDictionaryResponse(_ handler :  @escaping (NSDictionary?, NSError?, QwikHttp) -> Void)
    {
        HttpRequestPooler.sendRequest(self) { (data, response, error) -> Void in
            
            if let e = error
            {
                self.determineThread({ () -> () in
                    handler(nil,e, self)
                })
            }
            else
            {
                if let d : NSDictionary = NSDictionary.fromData(data)
                {
                    self.determineThread({ () -> () in
                        handler(d,nil,self)
                    })
                }
            }
        }
    }
    
    @objc open func getArrayOfDictionariesResponse(_ handler :  @escaping ([NSDictionary]?, NSError?, QwikHttp) -> Void)
    {
        HttpRequestPooler.sendRequest(self) { (data, response, error) -> Void in
            
            if let e = error
            {
                self.determineThread({ () -> () in
                    handler(nil,e, self)
                })
            }
            else
            {
                if let d : [NSDictionary] = NSDictionary.arrayFromData(data)
                {
                    self.determineThread({ () -> () in
                        handler(d,nil,self)
                    })
                }
            }
        }
    }
    
}


//this class is used to pool our requests and also to avoid the need to retain our QwikRequest objects
private class HttpRequestPooler
{
    class func sendRequest(_ requestParams : QwikHttp!, handler: @escaping (Data?, URLResponse?, NSError?) -> Void)
    {
        if QwikHttpConfig.loggingLevel.rawValue >= QwikHttpLoggingLevel.debug.rawValue
        {
            NSLog("QwikHttp: Preparing Request For Send")
        }
        
        //make sure our request url is valid
        guard let url = URL(string: requestParams.urlString)
            else
        {
            requestParams.responseError = NSError(domain: "QwikHTTP", code: 500, userInfo:["Error" : "Invalid URL"])
            handler(nil,nil, requestParams.responseError)
            
            if QwikHttpConfig.loggingLevel.rawValue >= QwikHttpLoggingLevel.errors.rawValue
            {
                requestParams.printDebugInfo()
            }
            
            return
        }
        
        //see if this request should be intercepted and if so call the interceptor.
        //don't worry about a completion handler since this should be called by the interceptor
        if let interceptor = QwikHttpConfig.requestInterceptor, requestParams.avoidRequestInterceptor == false , interceptor.shouldInterceptRequest(requestParams), requestParams.wasIntercepted == false
        {
            requestParams.wasIntercepted = true
            
            if QwikHttpConfig.loggingLevel.rawValue >= QwikHttpLoggingLevel.debug.rawValue
            {
                NSLog("QwikHttp: Request being intercepted")
            }
            
            interceptor.interceptRequest(requestParams, handler: handler)
            return
        }
        
        //create our http request
        let request = NSMutableURLRequest(url: url, cachePolicy: requestParams.cachePolicy, timeoutInterval: requestParams.timeOut)
        
        //add all of our standard headers if they are not yet added and the avoid flag is not set
        if requestParams.avoidStandardHeaders == false
        {
            for(key, value) in QwikHttpConfig.standardHeaders
            {
                if !requestParams.headers.keys.contains(key)
                {
                    _ = requestParams.addHeader(key, value: value)
                }
            }
        }
        
        //set up our http method and add headers
        request.httpMethod = HttpRequestPooler.paramTypeToString(requestParams.httpMethod)
        for(key, value) in requestParams.headers
        {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        //set up our parameters
        if requestParams.parameterType == .formEncoded  && requestParams.params.count > 0
        {
            //convert parameters to form encoded values and set to body
            if let params = requestParams.params as? [String : String]
            {
                request.httpBody = QwikHttp.paramStringFrom(params).data(using: String.Encoding.utf8)
                
                //set our body so we can view it later for debug purposes
                _ = requestParams.setBody(request.httpBody)
                
                //set the request type headers
                //application/x-www-form-urlencoded
                _ = requestParams.addHeader("Content-Type", value: "application/x-www-form-urlencoded")
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            }
                
                //if we couldn't encode the values, then perhaps json was passed in unexpectedly, so try to parse it as json.
            else
            {
                _ = requestParams.setParameterType(.json)
            }
        }
        
        //try json parsing, note that formEncoding could have changed the type if there was an error, so don't use an else if
        else if requestParams.parameterType == .json && requestParams.params.count > 0
        {
            //convert parameters to json string and form and set to body
            do {
                let data = try JSONSerialization.data(withJSONObject: requestParams.params, options: JSONSerialization.WritingOptions.prettyPrinted)
                request.httpBody = data
                
                //set our body so we can view it later for debug purposes
                _ = requestParams.setBody(request.httpBody)
            }
            catch let JSONError as NSError {
                
                requestParams.responseError = JSONError
                
                if QwikHttpConfig.loggingLevel.rawValue >= QwikHttpLoggingLevel.errors.rawValue
                {
                    requestParams.printDebugInfo()
                }
                
                
                handler(nil,nil,JSONError)
                return
            }
            
            //set the request type headers
            _ = requestParams.addHeader("Content-Type", value: "application/json")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        //set our body from data
        else if let body = requestParams.body
        {
            request.httpBody = body
        }
        
        
        //show our spinner
        var showingSpinner = false
        if let title = requestParams.loadingTitle, let indicatorDelegate = QwikHttpConfig.loadingIndicatorDelegate
        {
            indicatorDelegate.showIndicator(title)
            showingSpinner = true
        }
        
        if QwikHttpConfig.loggingLevel.rawValue >= QwikHttpLoggingLevel.debug.rawValue
        {
            NSLog("QwikHttp: Starting Request Send")
        }
        
        //send our request and do a bunch of common stuff before calling our response handler
        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (responseData, urlResponse, error) -> Void in
            
            if QwikHttpConfig.loggingLevel.rawValue >= QwikHttpLoggingLevel.debug.rawValue
            {
                NSLog("QwikHttp: Request Returned")
            }
            
            //set the values straight to the request object so we can read it if needed.
            requestParams.responseData = responseData
            requestParams.responseError = error as NSError?
            
            //set our response string
            if let responseString = self.getResponseString(responseData)
            {
                requestParams.responseString = responseString as NSString
            }
            
            //hide our spinner
            if let indicatorDelegate = QwikHttpConfig.loadingIndicatorDelegate , showingSpinner == true
            {
                indicatorDelegate.hideIndicator()
            }
            
            //check the responseCode to make sure its valid
            if let httpResponse = urlResponse as? HTTPURLResponse {
                
                requestParams.response = httpResponse
                requestParams.responseStatusCode = httpResponse.statusCode
                
                if let interceptor = QwikHttpConfig.responseInterceptor
                {
                    interceptor.didSend?(requestParams)
                }
                
                //see if we are configured to use an interceptor and if so, check it to see if we should use it
                if let interceptor = QwikHttpConfig.responseInterceptor , !requestParams.wasIntercepted &&  interceptor.shouldInterceptResponse(httpResponse) && !requestParams.avoidResponseInterceptor
                {
                    if QwikHttpConfig.loggingLevel.rawValue >= QwikHttpLoggingLevel.debug.rawValue
                    {
                        NSLog("QwikHttp: Response being intercepted")
                    }
                    
                    //call the interceptor and return. The interceptor will call our handler.
                    requestParams.wasIntercepted = true
                    interceptor.interceptResponse(requestParams, handler: handler)
                    return
                }
                
                //error for invalid response
                //in order to be considered successful the response must be in the 200's
                if httpResponse.statusCode / 100 != 2 && error == nil
                {
                    //try to parse the result into an error dictionary of json, since some apis return this way
                    //if that doesn't happen then we'll just return a generic user info dictionary
                    var responseDict  = ["Error": "Error Response Code" as AnyObject]
                    if let responseString = requestParams.responseString
                    {
                        if let errorDict = NSDictionary.fromJsonString(responseString as String) as? [String : AnyObject]
                        {
                            responseDict = errorDict
                        }
                    }
                    
                    let error = NSError(domain: "QwikHttp", code: httpResponse.statusCode, userInfo: responseDict )
                    requestParams.responseError = error
                    
                    if QwikHttpConfig.loggingLevel.rawValue >= QwikHttpLoggingLevel.errors.rawValue
                    {
                        requestParams.printDebugInfo()
                    }
                    
                    handler(responseData, urlResponse, error)
                    return
                }
            }
            
            if QwikHttpConfig.loggingLevel.rawValue >= QwikHttpLoggingLevel.requests.rawValue
            {
                requestParams.printDebugInfo()
            }
            
            handler(responseData, urlResponse, error as NSError?)
        }).resume()
    }
    
    //convert our enum to a string used for the request
    open class func paramTypeToString(_ type: HttpRequestMethod) -> String!
    {
        switch(type)
        {
        case HttpRequestMethod.post:
            return "POST"
        case HttpRequestMethod.put:
            return "PUT"
        case HttpRequestMethod.get:
            return "GET"
        case HttpRequestMethod.delete:
            return "DELETE"
        case HttpRequestMethod.patch:
            return "PATCH"
        }
    }
    
    //a helper to to return an optional string from our ns data
    class func getResponseString(_ data : Data?) -> String?
    {
        if let d = data{
            return String(data: d, encoding: String.Encoding.utf8)
        }
        else
        {
            return nil
        }
    }
    
}


        


