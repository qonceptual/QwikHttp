//
//  QwikConversion.swift
//  Pods
//
//  Created by Logan Sease on 2/25/16.
//
//

import Foundation
import QwikJson

public protocol QwikDataConversion {
    static func fromData<T>(_ data : Data?) -> T? ;
    static func arrayFromData<T>(_ data : Data?) -> [T]?
}


extension NSNumber : QwikDataConversion
{
    public static func fromData<T>(_ data : Data?) -> T?{
        if let d = data, let string = String(data: d, encoding: String.Encoding.utf8), let int = Int64(string){
            return NSNumber(value: int as Int64) as? T
        }
        else
        {
            return nil
        }
    }
    
    public static func arrayFromData<T>(_ data : Data?) -> [T]?
    {
        if let d = data{
            if let string =  String(data: d, encoding: String.Encoding.utf8)
            {
                let array = string.components(separatedBy: ",")
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

extension String : QwikDataConversion{
    
    public static func fromData<T>(_ data : Data?) -> T?{
        if let d = data{
            return String(data: d, encoding: String.Encoding.utf8) as? T
        }
        else
        {
            return nil
        }
    }
    
    public static func arrayFromData<T>(_ data : Data?) -> [T]?
    {
        if let d = data{
            if let string =  String(data: d, encoding: String.Encoding.utf8)
            {
                let array = string.components(separatedBy: ",")
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

extension Bool : QwikDataConversion
{
    public static func fromData<T>(_ data : Data?) -> T?{
        return true as? T
    }
    
    public static func arrayFromData<T>(_ data : Data?) -> [T]?
    {
        return nil
    }
}

extension Data : QwikDataConversion
{
    public static func fromData<T>(_ data : Data?) -> T?{
        return data as? T
    }
    
    public static func arrayFromData<T>(_ data : Data?) -> [T]?
    {
        return nil
    }
}

extension NSDictionary : QwikDataConversion
{
    public static func fromData<T>(_ data : Data?) -> T?{
        
        if let d = data{
            //parse our data as a dictionary and call our dictionary handler
            do {
                let JSON = try JSONSerialization.jsonObject(with: d, options:JSONSerialization.ReadingOptions(rawValue: 0))
                return JSON as? T
            }
            catch _ as NSError {}
        }
        
        return nil
    }
    
    public static func arrayFromData<T>(_ data : Data?) -> [T]?
    {
        if let d = data{
            
            //parse our data as a dictionary and call our dictionary handler
            do {
                let JSON = try JSONSerialization.jsonObject(with: d, options:JSONSerialization.ReadingOptions(rawValue: 0))
                return JSON as? [T]
            }
            catch _ as NSError {}
        }
        return nil
    }
}

extension QwikJson : QwikDataConversion
{
    public static func fromData<T>(_ data : Data?) -> T?{
        
        if let d = data{
            //parse our data as and deserialize it into an object
            do {
                let JSON = try JSONSerialization.jsonObject(with: d, options:JSONSerialization.ReadingOptions(rawValue: 0))
                if let dict = JSON as?  [AnyHashable: Any]
                {
                    return self.object(from: dict) as? T
                }
            }
            catch _ as NSError {}
        }
        
        return nil
    }
    
    public static func arrayFromData<T>(_ data : Data?) -> [T]?
    {
        if let d = data{
            //parse our data as and deserialize it into an object
            do {
                let JSON = try JSONSerialization.jsonObject(with: d, options:JSONSerialization.ReadingOptions(rawValue: 0))
                if let dict = JSON as?  [[AnyHashable: Any]]
                {
                    if let array =  self.array(forJsonArray: dict, of: self)
                    {
                        var resultArray : [T] = []
                        for(object) in array
                        {
                            resultArray.append((object as? T)!)
                        }
                        return resultArray
                    }
                }
            }
            catch _ as NSError {}
        }
        
        return nil
    }
}




