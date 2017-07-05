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

@objc open class QwikHelper : NSObject,  QwikHttpLoadingIndicatorDelegate, QwikHttpResponseInterceptor, QwikHttpRequestInterceptor
{
    //standard singleton method stuff
    open class func shared() -> QwikHelper {
        struct Singleton {
            static let instance = QwikHelper()
        }
        return Singleton.instance
    }
    
    open func configure()
    {
        //configure qwikHttp
        QwikHttpConfig.setDefaultTimeOut(300)
        QwikHttpConfig.defaultParameterType = .json
        QwikHttpConfig.defaultLoadingTitle = "Loading"
        QwikHttpConfig.defaultCachePolicy = .reloadIgnoringLocalCacheData
        
        //set our loading indicator and response interceptor. This isn't required, but done just for test
        //and example
        QwikHttpConfig.loadingIndicatorDelegate = self
        QwikHttpConfig.responseInterceptor = self
        
        //send our first request
    }
    
    //show and hide indicators using swift spinner
    @objc open func showIndicator(_ title: String!)
    {
        QwikLoadingIndicator.shared().show(withTitle: title)
    }
    @objc open func hideIndicator()
    {
        QwikLoadingIndicator.shared().hide()
    }
    
    public func shouldInterceptRequest(_ request: QwikHttp!) -> Bool
    {
        return true
    }
    public func interceptRequest(_ request : QwikHttp!,  handler: @escaping (Data?, URLResponse?, NSError?) -> Void)
    {
        handler(request.responseData, request.response, request.responseError)
        //TODO: check to see if our current token is invalid
        //if the token needs refreshing, refresh it- then save the new token to your auth service
        //now update the header in the QwikHttp request and reset and run it again.
        //call the handler with the results of the new request.
    }
    
    public func shouldInterceptResponse(_ response: URLResponse!) -> Bool
    {
        return false
    }
    
    public func interceptResponse(_ request: QwikHttp!, handler: @escaping (Data?, URLResponse?, NSError?) -> Void) {
        //TODO: check to see if response means that the token must be refreshed
        //if the token needs refreshing, refresh it- then save the new token to your auth service
        //now update the header in the QwikHttp request and reset and run it again.
        //call the handler with the results of the new request.
    }

    

}

