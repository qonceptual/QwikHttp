//
//  NSDictionary+Json.h
//  Pods
//
//  Created by Logan Sease on 12/13/15.
//
//

#import <Foundation/Foundation.h>

@interface NSDictionary (QJson)

-(NSString*)toJsonString;
+(NSDictionary*)fromJsonString:(NSString*)json;

@end

@interface NSArray (QJson)

-(NSString*)toJsonString;
+(NSArray*)fromJsonString:(NSString*)json;

@end
