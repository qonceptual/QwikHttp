//
//  QJsonable.h
//  EZWaves
//
//  Created by Logan Sease on 11/19/14.
//  Copyright (c) 2014 Qonceptual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NSArrayDictionary+QJson.h"
#import "QwikJson.h"

@interface QwikJsonManagedObject : NSManagedObject//<NSCoding>
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
+(NSArray<NSDictionary*>*)jsonArrayFromArray:(NSArray<QwikJsonManagedObject*>*)inputArray ofClass:(Class)modelClass;

-(void)addProperty:(NSString*)key toDictionary:(NSMutableDictionary*)dict;

//override in subclass to specify a nested model that should be deserialized
//may also be useful if the api is returning a Number ID field but you want to store it as a String
+(Class)classForKey:(NSString*)key;

/*** override in subclass to perform some custom deserizliation or change property keys ***/
-(void)writeObjectFrom:(NSDictionary*)inputDictionary forKey:(NSString*)key toProperty:(NSString*)property;

/*** override in subclass to specify a new key or perform some custom action on serialize ***/
-(void)serializeObject:(NSObject*)object withKey:(NSString*)key toDictionary:(NSMutableDictionary*)dictionary;
/**
 * Override this in your subclasses to allow for any special data types to be set into the object,
 * This is necessary for any date fields
 * for example if([key isEqualToString:@"date"]) [self setDateValue:value forKey:key];
 * make sure you call the super method if you are not handling this yourself!
 */
-(void)setValue:(id)value forKey:(NSString *)key;

/**** override this method to specify field renaming mappings ***/
+(NSDictionary<NSString*,NSString*>*)apiToObjectMapping;

//return field names here that should not be written during serialization
+(NSArray<NSString*>*)transientProperties;

@end