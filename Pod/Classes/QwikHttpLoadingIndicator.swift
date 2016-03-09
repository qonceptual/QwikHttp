//
//  File.swift
//  Pods
//
//  Created by Logan Sease on 3/9/16.
//
//

import Foundation

public class QwikHttpLoadingIndicator : NSObject
{
    var indicator : UIActivityIndicatorView?
    public var yOffset : CGFloat = -60
    
    // shared instance
    public class func shared() -> QwikHttpLoadingIndicator {
        struct Singleton {
            static let instance = QwikHttpLoadingIndicator()
        }
        return Singleton.instance
    }
    
    public func showWithTitle(title: String?)
    {
        if NSClassFromString("UIActivityIndicatorView") != nil  {
            if let oldIndicator = self.indicator
            {
                oldIndicator.removeFromSuperview()
            }
            
            let indicator = UIActivityIndicatorView(frame: CGRectMake(0,0,60,60))
            guard let window = UIApplication.sharedApplication().keyWindow else
            {
                return
            }
            
            window.addSubview(indicator)
            indicator.center = CGPointMake(window.center.x, window.center.y + self.yOffset)
            indicator.color = UIColor.blackColor()
            indicator.transform = CGAffineTransformMakeScale(2.5, 2.5)
            indicator.startAnimating()
            self.indicator = indicator
        }
    }
    
    public func hide()
    {
        if let indicator = self.indicator
        {
            indicator.stopAnimating()
            indicator.removeFromSuperview()
            self.indicator = nil
        }
    }
    
}