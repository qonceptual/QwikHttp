//
//  QJsonable.h
//  EZWaves
//
//  Created by Logan Sease on 11/19/14.
//  Copyright (c) 2014 Qonceptual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSArrayDictionary+QJson.h"


//these are properties that are declared on all objects. Since we don't want to pass them into the api
//they are always transient. If you wish to pass one of these variables in, simply rename the field using
//the apiToObjectMapping method
#define kDefaultTransientProperties @[@"superclass", @"hash", @"debugDescription", @"description"]

@interface QwikJson : NSObject//<NSCoding>
//note in order for serialization to work, I am moving all properties to the specific class
//and leaving all, including the ID out of the base class.
//@property (nonatomic, strong) NSString* id;

//convert an object to NSData
- (NSData*)toJSONData;

//convert to a dictionary
-(NSDictionary*)toDictionary;

//instanciate from a dictionary
+(id)objectFromDictionary:(NSDictionary*)inputDictionary;

//instanciate an array of objects from an array of dictionaries
+(NSArray*)arrayForJsonArray:(NSArray*)inputArray ofClass:(Class)parseClass;
+(NSArray<NSDictionary*>*)jsonArrayFromArray:(NSArray<QwikJson*>*)inputArray ofClass:(Class)modelClass;

-(void)addProperty:(NSString*)key toDictionary:(NSMutableDictionary*)dict;

//override in subclass to specify a nested model that should be deserialized
//may also be useful if the api is returning a Number ID field but you want to store it as a String
+(Class)classForKey:(NSString*)key;

//override in subclass to perform some custom deserizliation or change property keys
-(void)writeObjectFrom:(NSDictionary*)inputDictionary forKey:(NSString*)key toProperty:(NSString*)property;

//override in subclass to specify a new key or perform some custom action on serialize
-(void)serializeObject:(NSObject*)object withKey:(NSString*)key toDictionary:(NSMutableDictionary*)dictionary;
/**
 * Override this in your subclasses to allow for any special data types to be set into the object,
 * This is necessary for any date fields
 * for example if([key isEqualToString:@"date"]) [self setDateValue:value forKey:key];
 * make sure you call the super method if you are not handling this yourself!
 */
-(void)setValue:(id)value forKey:(NSString *)key;

//easily read and write objects to the user defaults
-(void)writeToPreferencesWithKey:(NSString*)key;
+(id)readFromPrefencesWithKey:(NSString*)key;

//initilization helpers
+(id)testObject; //empty object
+(id)objectWithId:(NSString*)objectId; //empty object with id=objectId

//override this method to specify field renaming mappings
+(NSDictionary<NSString*,NSString*>*)apiToObjectMapping;

//return field names here that should not be written during serialization
+(NSArray<NSString*>*)transientProperties;

@end


/****
 * THE FOLLOWING CLASSES ARE DEFINED TO HELP PARSE TO AND FROM VARIOUS DATABASE FIELD
 * NOTE that to use these db field types in your objects, you must return the class type in the classForKey method
 * of your data object
 */

//this protocol represents the functions that all fields must implement
@protocol DBField <NSObject>
+(id)objectFromDbString:(NSString*)dbString;
-(NSString*)toDbFormattedString;
-(NSString*)displayString;
@end

//this class represents a date formatted like 2015-MM-DD
@interface DBDate : NSObject<DBField>
-(id)initWithDate:(NSDate*)date;
//use this to customize the date format
+(void)setDateFormat:(NSString*)format;
@property(nonatomic,strong)NSDate * date;
@end

//this class represents a time formatted "HH:MM:SS" in UTC
@interface DBTime : NSObject<DBField>
-(id)initWithDate:(NSDate*)date;
//use this to customize the date format
+(void)setDateFormat:(NSString*)format;
@property(nonatomic,strong)NSDate * date;
@end

//this class represents a date time formatted like 2015-01-01T10:15:30 in UTC
@interface DBDateTime : NSObject<DBField>
-(id)initWithDate:(NSDate*)date;
-(id)initWithDBDate:(DBDate*)dbDate andDBTime:(DBTime*)dbTime;
//use this to customize the date format
+(void)setDateFormat:(NSString*)format;
@property(nonatomic,strong)NSDate * date;
@end

//this class represents a time stamp formatted like 14128309481 in UTC
@interface DBTimeStamp : NSObject<DBField>
-(id)initWithDate:(NSDate*)date;
@property(nonatomic,strong)NSDate * date;
@end