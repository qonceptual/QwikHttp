//
//  QwikConversion.swift
//  Pods
//
//  Created by Logan Sease on 2/25/16.
//
//

import Foundation
import QwikJson

public protocol QwikConversion {
    static func fromData<T>(data : NSData?) -> T? ;
    static func arrayFromData<T>(data : NSData?) -> [T]?
}


extension NSNumber : QwikConversion
{
    public static func fromData<T>(data : NSData?) -> T?{
        if let d = data, string = String(data: d, encoding: NSUTF8StringEncoding), int = Int64(string){
            return NSNumber(longLong: int) as? T
        }
        else
        {
            return nil
        }
    }
    
    public static func arrayFromData<T>(data : NSData?) -> [T]?
    {
        if let d = data{
            if let string =  String(data: d, encoding: NSUTF8StringEncoding)
            {
                let array = string.componentsSeparatedByString(",")
                var resultArray : [T] = []
                for(string) in array
                {
                    resultArray.append((string as? T)!)
                }
                return resultArray
            }
        }
        return nil
    }
}

extension String : QwikConversion{
    
    public static func fromData<T>(data : NSData?) -> T?{
        if let d = data{
            return String(data: d, encoding: NSUTF8StringEncoding) as? T
        }
        else
        {
            return nil
        }
    }
    
    public static func arrayFromData<T>(data : NSData?) -> [T]?
    {
        if let d = data{
            if let string =  String(data: d, encoding: NSUTF8StringEncoding)
            {
                let array = string.componentsSeparatedByString(",")
                var resultArray : [T] = []
                for(string) in array
                {
                    resultArray.append((string as? T)!)
                }
                return resultArray
            }
        }
        return nil
    }
}

extension Bool : QwikConversion
{
    public static func fromData<T>(data : NSData?) -> T?{
        return true as? T
    }
    
    public static func arrayFromData<T>(data : NSData?) -> [T]?
    {
        return nil
    }
}

extension NSData : QwikConversion
{
    public static func fromData<T>(data : NSData?) -> T?{
        return data as? T
    }
    
    public static func arrayFromData<T>(data : NSData?) -> [T]?
    {
        return nil
    }
}

extension NSDictionary : QwikConversion
{
    public static func fromData<T>(data : NSData?) -> T?{
        
        if let d = data{
            //parse our data as a dictionary and call our dictionary handler
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(d, options:NSJSONReadingOptions(rawValue: 0))
                return JSON as? T
            }
            catch _ as NSError {}
        }
        
        return nil
    }
    
    public static func arrayFromData<T>(data : NSData?) -> [T]?
    {
        if let d = data{
            
            //parse our data as a dictionary and call our dictionary handler
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(d, options:NSJSONReadingOptions(rawValue: 0))
                return JSON as? [T]
            }
            catch _ as NSError {}
        }
        return nil
    }
}