//
//  QwikHelper.swift
//  QwikHttp
//
//  Created by Logan Sease on 3/9/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//  This is a singleton class used to implement the indicator and interceptor protocols.
//  This could be done in your app delegate or in a data service class--- or could be contained in a view
//  Controller. but a singleton makes it easy and avoids any memory releasing issues.

import Foundation
import QwikHttp
import SwiftSpinner

@objc public class QwikHelper : NSObject,  QwikHttpLoadingIndicatorDelegate, QwikHttpResponseInterceptor, QwikHttpObjcResponseInterceptor, QwikHttpRequestInterceptor
{
    
    //standard singleton method stuff
    public class func shared() -> QwikHelper {
        struct Singleton {
            static let instance = QwikHelper()
        }
        return Singleton.instance
    }
    
    public func configure()
    {
        //configure qwikHttp
        QwikHttpConfig.setDefaultTimeOut(300)
        QwikHttpConfig.defaultParameterType = .Json
        QwikHttpConfig.defaultLoadingTitle = "Loading"
        QwikHttpConfig.defaultCachePolicy = .ReloadIgnoringLocalCacheData
        
        //set our loading indicator and response interceptor. This isn't required, but done just for test
        //and example
        QwikHttpConfig.loadingIndicatorDelegate = self
        QwikHttpConfig.responseInterceptor = self
        
        //send our first request
    }
    
    //show and hide indicators using swift spinner
    @objc public func showIndicator(title: String!)
    {
        SwiftSpinner.show(title)
    }
    @objc public func hideIndicator()
    {
        SwiftSpinner.hide()
    }
    
    @objc public func shouldInterceptResponse(response: NSURLResponse!) -> Bool
    {
        //TODO check for an unautorized response and return true if so
        return true
    }
    public func interceptResponse(request : QwikHttp!, handler: (NSData?, NSURLResponse?, NSError?) -> Void)
    {
        handler(request.responseData, request.response, request.responseError)
        //TODO check to see if response means that the token must be refreshed
        //if the token needs refreshing, refresh it- then save the new token to your auth service
        //now update the header in the QwikHttp request and reset and run it again.
        //call the handler with the results of the new request.
    }
    
    @objc public func interceptResponseObjc(request : QwikHttpObjc!, handler: (NSData?, NSURLResponse?, NSError?) -> Void)
    {
        handler(request.responseData, request.response, request.responseError)
    }
    
    public func shouldInterceptRequest(request: QwikHttp!) -> Bool
    {
        //check for an expired token date on your current token
        return true
    }
    public func interceptRequest(request : QwikHttp!,  handler: (NSData?, NSURLResponse?, NSError?) -> Void)
    {
        //TODO refresh your token, restart the request
        //update the auth headers with the new token
        request.getResponse(NSData.self) { (data, error, request) -> Void! in
            handler(data,request.response,error)
        }
    }
}

