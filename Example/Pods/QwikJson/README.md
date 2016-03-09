# QwikJson

[![CI Status](http://img.shields.io/travis/Logan Sease/QwikJson.svg?style=flat)](https://travis-ci.org/Logan Sease/QwikJson)
[![Version](https://img.shields.io/cocoapods/v/QwikJson.svg?style=flat)](http://cocoapods.org/pods/QwikJson)
[![License](https://img.shields.io/cocoapods/l/QwikJson.svg?style=flat)](http://cocoapods.org/pods/QwikJson)
[![Platform](https://img.shields.io/cocoapods/p/QwikJson.svg?style=flat)](http://cocoapods.org/pods/QwikJson)

## Summary
In our ReSTful API world, we are constantly passing JSON objects to our api and receiving them back. Constantly serializating these objects to and from json string and dictionaries can be cumbersome and can make your model classes and data services start to fill up with boiler plate parsing code.

To solve this, I introduce QwikJson. An amazingly powerful and simple library for serializing and deserializing json objects.

Simply have your model classes extend QwikJson and the world shall become your oyster.

QwikJson makes converting objects to dictionaries and arrays of dictionaries (and Vice Versa) a breeze. It includes support for nested model objects, nested array model objects, multiple styles of dates and times, simple storage to NSUserDefaults and conversion to and from JSON Strings.


## Installation

QwikJson is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "QwikJson"
```

And import the following Header file
```ruby
#import "QwikJson.h"
```

This pod is written in Objective-C but works great with Swift projects as well.

## Usage

make a model class and extend QwikJson, and add your fields
```objective-c
//menu.h
@interface Menu : QwikJson
@property(nonatomic,strong)NSString * name;
@property(nonatomic,strong)NSArray * menuItems;
@end
```

now you can convert from dictionaries and vice versa with ease
```objective-c
//deserialize
menu = [Menu objectFromDictionary:dictionary];

//serialize again
dictionary = [menu toDictionary];
```

Use Nested Objects (even nested arrays) and custom date serlizers
```objective-c
//restaurant.h
@interface Restaurant : QwikJson
@property(nonatomic,strong)NSString * image_url;
@property(nonatomic,strong)NSString * name;
@property(nonatomic,strong)NSArray * menus;
@property(nonatomic,strong)DBTimeStamp * createdAt;
@end

//restaurant.m
+(Class)classForKey:(NSString*)key
{
    if([key isEqualToString:@"menus"])
    {
        return [Menu class];
    }
    if([key isEqualToString:@"createdAt"])
    {
        return [DBTimeStamp class];
    }

    return [super classForKey:key];
}

```

Customize field names if they don't match the database
```objective-c
+(Class)classForKey:(NSString*)key
{
    if([key isEqualToString:@"menu_items"] || [key isEqualToString:@"menuItems"])
    {
        return [MenuItem class];
    }
    return [super classForKey:key];
}

//override in subclass to perform some custom deserizliation or change property keys
-(void)writeObjectFrom:(NSDictionary*)inputDictionary forKey:(NSString*)key toProperty:(NSString*)property
{
    //adjust the property name since the database is formatted with _'s instead of camel case
    if([property isEqualToString:@"menu_items"])
    {
        property = @"menuItems";
    }

    [super writeObjectFrom:inputDictionary forKey:key toProperty:property];
}

//override in subclass to specify a new key or perform some custom action on serialize
-(void)serializeObject:(NSObject*)object withKey:(NSString*)key toDictionary:(NSMutableDictionary*)dictionary
{
    //adjust the property name since the database is formatted with _'s instead of camel case
    if([key isEqualToString:@"menuItems"])
    {
        key = @"menu_items";
    }
    [super serializeObject:object withKey:key toDictionary:dictionary];
}
```

Write straight to preferences
```objective-c
[self.restaurant writeToPreferencesWithKey:@"data"];
self.restaurant = [Restaurant readFromPrefencesWithKey:@"data"];
```

Convert to and from Strings
```objective-c
@interface NSDictionary (QwikJson)
-(NSString*)toJsonString;
+(NSDictionary*)fromJsonString:(NSString*)json;
@end

@interface NSArray (QwikJson)
-(NSString*)toJsonString;
+(NSArray*)fromJsonString:(NSString*)json;
@end
```


## Supported Field Types Types
- Boolean
- NSString
- NSArray
- NSNumber

### Custom Date Serializers, handle parsing various date / time formats

####DBDate            
2015-12-30

####DBDateTime        
2015-01-01T10:15:30 

####DBDateTimeStamp   
0312345512

####DBTime            
12:00:00

Note that you can customize the date formats by calling setDateFormat on the date class.
```objective-c
[DBDate setDateFormat:@"MM/DD/YYYY"];
```

## Android

Inside this repo and in the android directory, you will also find a very similar class, QwikJson.java that offers very similar functionality for Android and other Java Platforms.

## Further Notes

In addition to parsing and serializing JSON, the other essential pieice of communicatiing with RESTful APIs is a good
networking library.
Consider using QwikHttp in combination with this library to complete your toolset.
https://github.com/qonceptual/QwikHttp

Also, checkout the SeaseAssist pod for a ton of great helpers to make writing your iOS code even simpler!
https://github.com/logansease/SeaseAssist


## Author

Logan Sease, logan.sease@qonceptual.com

## License

QwikJson is available under the MIT license. See the LICENSE file for more info.
