//
//  QwikHttp.swift
//  oAuthExample
//
//  Created by Logan Sease on 1/26/16.
//  Copyright © 2016 Logan Sease. All rights reserved.
//

import Foundation


public typealias HttpStringCompletionHandler = (responseString: String!) -> Void
public typealias HttpDictionaryCompletionHandler = (responseDictionary: [String : AnyObject]!) -> Void
public typealias HttpArrayCompletionHandler = (responseArray: [[String : AnyObject]]!) -> Void
public typealias HttpDataCompletionHandler = (responseData: NSData!) -> Void
public typealias HttpErrorCompletionHandler = (errorResponse: String?, error: NSError!, statusCode: NSInteger?) -> Void
public typealias HttpGlobalCompletionHandler = (success: Bool) -> Void

/****** REQUEST TYPES *******/
public enum HttpRequestMethod : String {
    case get = "GET", post = "POST", delete = "DELETE", put = "PUT"
}

public enum ParameterType
{
    case json, formEncoded
}

public class QwikHttp {
    
    /***** REQUEST VARIABLES ******/
    private var urlString : String!
    private var httpMethod : HttpRequestMethod!
    private var headers : [String : String]!
    private var params : [String : AnyObject]!
    private var body: NSData?
    private var parameterType : ParameterType!
    public var error : NSError?
    public var result : NSData?
    public var responseStatusCode: NSInteger?
    private var cachePolicy: NSURLRequestCachePolicy!
    
    private var stringHandler : HttpStringCompletionHandler?
    private var dictionaryHandler : HttpDictionaryCompletionHandler?
    private var arrayHandler : HttpArrayCompletionHandler?
    private var dataHandler : HttpDataCompletionHandler?
    private var errorHandler : HttpErrorCompletionHandler?
    private var globalHandler : HttpGlobalCompletionHandler?
    private var sent = false
    
    
    private var timeOut : Double!
    
    /**** REQUIRED INITIALIZER*****/
    public init(urlString: String!, httpMethod: HttpRequestMethod!)
    {
        self.urlString = urlString
        self.httpMethod = httpMethod
        self.headers = [:]
        self.params = [:]
        self.parameterType = .json
        self.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        self.timeOut = 20
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
    
    /********* RESPONSE HANDLERS *************/
    
    public func stringResponse(handler: HttpStringCompletionHandler?) -> QwikHttp
    {
        stringHandler = handler
        return self
    }
    
    public func dictionaryResponse(handler: HttpDictionaryCompletionHandler?) -> QwikHttp
    {
        dictionaryHandler = handler
        return self
    }
    
    public func arrayResponse(handler: HttpArrayCompletionHandler?) -> QwikHttp
    {
        arrayHandler = handler
        return self
    }
    public func dataResponse(handler: HttpDataCompletionHandler?) -> QwikHttp
    {
        dataHandler = handler
        return self
    }
    public func errorResponse(handler: HttpErrorCompletionHandler?) -> QwikHttp
    {
        errorHandler = handler
        return self
    }
    
    //TODO improve completion handlers with generics
    //    func setHandler<T>(handler: (responseObject: T!) -> Void)
    //    {
    //
    //    }
    
    
    //Send the request!
    public func send(handler: HttpGlobalCompletionHandler? = nil)
    {
        self.sent = true
        self.globalHandler = handler
        HttpRequestPooler.sendRequest(self)
    }
    
    //reset our completion handlers and response data
    public func reset()
    {
        self.globalHandler = nil
        self.errorHandler = nil
        self.arrayHandler = nil
        self.stringHandler = nil
        self.dictionaryHandler = nil
        self.dataHandler = nil
        self.responseStatusCode = nil
        self.error = nil
        self.result = nil
        self.sent = false
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
        NSLog("QwikHttp Error: Request to URL %@ dealloc'ed before it was sent. You likely forgot to call send() or need to add a strong reference to the object.",urlString)
        if let errorHandler = self.errorHandler
        {
            errorHandler(errorResponse: nil, error: NSError(domain: "QwikHttp", code: 0, userInfo: ["Error": "Thread was not run before being deallocated. Did you forget to call send()?"]), statusCode: 0)
        }
    }
    
}

//this class is used to pool our requests and also to avoid the need to retain our QwikRequest objects
private class HttpRequestPooler
{
    class func sendRequest(requestParams : QwikHttp!)
    {
        //make sure our request url is valid
        guard let url = NSURL(string: requestParams.urlString)
            else
        {
            mainThread({ () -> () in
                if let errorHandler = requestParams.errorHandler
                {
                    let error = NSError(domain: "QwikHTTP", code: 0, userInfo: ["error" : "cannot parse response"])
                    errorHandler(errorResponse: nil, error: error, statusCode: nil)
                }
                if let globalHandler = requestParams.globalHandler
                {
                    globalHandler(success: false)
                }
            })
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
                request.HTTPBody = QwikHttp.paramStringFrom(params).dataUsingEncoding(NSUTF8StringEncoding)
                
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
                mainThread({ () -> () in
                    if let errorHandler = requestParams.errorHandler
                    {
                        errorHandler(errorResponse: nil, error: JSONError, statusCode: nil)
                    }
                    if let globalHandler = requestParams.globalHandler
                    {
                        globalHandler(success: false)
                    }
                })
                return
            }
            
            //set the request type headers
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        //send our request
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (responseData, urlResponse, error) -> Void in
            
            var responseStatusCode : NSInteger? = nil
            
            //set the values straight to the request object so we can read it if needed.
            requestParams.result = responseData
            requestParams.error = error
            
            //set the responseCode
            if let httpResponse = urlResponse as? NSHTTPURLResponse {
                responseStatusCode = httpResponse.statusCode
                
                requestParams.responseStatusCode = responseStatusCode
                
                if httpResponse.statusCode != 200
                {
                    mainThread({ () -> () in
                        if let errorHandler = requestParams.errorHandler
                        {
                            errorHandler(errorResponse: getResponseString(responseData), error: error, statusCode: httpResponse.statusCode)
                        }
                        if let globalHandler = requestParams.globalHandler
                        {
                            globalHandler(success: false)
                        }
                    })
                    return
                }
            }
            
            
            // the global error will be used to call the global response later and will add any parsing errors
            var globalError = error
            
            //if we have an error and an error handler, call the error handler.
            if let e = error, let errorHandler = requestParams.errorHandler
            {
                mainThread({ () -> () in
                    errorHandler(errorResponse: getResponseString(responseData), error: e, statusCode: responseStatusCode)
                })
            }
                
                //otherwise try to parse our response data into the corresponding types for our completion handlers
            else if let data = responseData
            {
                //return data to our data handler
                if let dataHandler = requestParams.dataHandler
                {
                    mainThread({ () -> () in
                        dataHandler(responseData: data)
                    })
                }
                
                if let stringHandler = requestParams.stringHandler
                {
                    //parse our data as a string and return it to the response handler
                    if let string = getResponseString(data)
                    {
                        mainThread({ () -> () in
                            stringHandler(responseString: string)
                        })
                    }else if globalError == nil
                    {
                        globalError = NSError(domain: "QwikHTTP", code: 0, userInfo: ["error" : "cannot parse response"])
                    }
                    
                }
                
                //parse for dictionary handler
                if let dictionaryHandler = requestParams.dictionaryHandler
                {
                    //parse our data as a dictionary and call our dictionary handler
                    do {
                        let JSON = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions(rawValue: 0))
                        if let dictionary = JSON as? [String : AnyObject] {
                            dictionaryHandler(responseDictionary: dictionary)
                        }
                        else
                        {
                            globalError = NSError(domain: "QwikHTTP", code: 0, userInfo: ["error" : "cannot parse response"])
                        }
                        
                    }
                    catch let JSONError as NSError {
                        globalError = JSONError
                    }
                    
                }
                
                //parse for array handler
                if let arrayHandler = requestParams.arrayHandler
                {
                    //parse our data as a dictionary and call our dictionary handler
                    do {
                        let JSON = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions(rawValue: 0))
                        if let array = JSON as? [[String : AnyObject]] {
                            arrayHandler(responseArray: array)
                        }
                        else
                        {
                            globalError = NSError(domain: "QwikHTTP", code: 0, userInfo: ["error" : "cannot parse response"])
                        }
                    }
                    catch let JSONError as NSError {
                        globalError = JSONError
                    }
                    
                }
                
                //check to see if we had a parse error and have an error handler
                if let e = globalError, let errorHandler = requestParams.errorHandler
                {
                    mainThread({ () -> () in
                        errorHandler(errorResponse: getResponseString(data), error: e, statusCode: responseStatusCode)
                    })
                }
            }
            
            //if we had any errors return it to our global ahndler
            if let globalHandler = requestParams.globalHandler
            {
                //parse data to a string
                let success = globalError == nil
                
                //call global handler
                mainThread({ () -> () in
                    globalHandler(success: success)
                })
                
            }
            
        })
        
        task.resume()
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
    
}
