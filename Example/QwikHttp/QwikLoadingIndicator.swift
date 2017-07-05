//
//  File.swift
//  Pods
//
//  Created by Logan Sease on 3/9/16.
//
//

import Foundation
import UIKit

//this is a very simple and basic loading indicator that you could incorporate into your project
//as a loading indicator for QwikHttp
open class QwikLoadingIndicator : NSObject
{
    var indicator : UIActivityIndicatorView?
    open var yOffset : CGFloat = -60
    
    // shared instance
    open class func shared() -> QwikLoadingIndicator {
        struct Singleton {
            static let instance = QwikLoadingIndicator()
        }
        return Singleton.instance
    }
    
    open func show(withTitle title: String?)
    {
        //TODO, add a label.
        if let oldIndicator = self.indicator
        {
            oldIndicator.removeFromSuperview()
        }
        
        let indicator = UIActivityIndicatorView(frame: CGRect(x: 0,y: 0,width: 60,height: 60))
        guard let window = UIApplication.shared.keyWindow else
        {
            return
        }
        
        window.addSubview(indicator)
        indicator.center = CGPoint(x: window.center.x, y: window.center.y + self.yOffset)
        indicator.color = UIColor.black
        indicator.transform = CGAffineTransform(scaleX: 2.5, y: 2.5)
        indicator.startAnimating()
        self.indicator = indicator
    }
    
    open func hide()
    {
        if let indicator = self.indicator
        {
            indicator.stopAnimating()
            indicator.removeFromSuperview()
            self.indicator = nil
        }
    }
    
}
