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

@objc public class QwikHelper : NSObject,  QwikHttpLoadingIndicatorDelegate, QwikHttpResponseInterceptor, QwikHttpObjcResponseInterceptor
{
    
    //standard singleton method stuff
    public class func shared() -> QwikHelper {
        struct Singleton {
            static let instance = QwikHelper()
        }
        return Singleton.instance
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
    @objc public func interceptResponse(request : QwikHttp!, handler: (NSData?, NSURLResponse?, NSError?) -> Void)
    {
        handler(request.responseData, request.response, request.responseError)
        //TODO check to see if response means that the token must be refreshed
        //if the token needs refreshing, refresh it- then save the new token to your auth service
        //now update the header in the QwikHttp request and reset and run it again. Pass in the 
        //call the handler with the results of the new request.
    }
    
    @objc public func interceptResponseObjc(request : QwikHttpObjc!, handler: (NSData?, NSURLResponse?, NSError?) -> Void)
    {
        handler(request.responseData, request.response, request.responseError)
    }
    
}

