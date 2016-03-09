//
//  ObjcViewController.m
//  QwikHttp
//
//  Created by Logan Sease on 3/8/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

#import "ObjcViewController.h"
#import "QwikHttp_Example-Swift.h"
#import "UIAlertController+Helpers.h"
#import "QwikHttp-Swift.h"

@implementation ObjcViewController

-(void)viewDidLoad
{
    //set our objective c response interceptor. See the docs and the helper for more info.
    //this isn't really required, just for testing and example
    QwikHttpConfig.responseInterceptorObjc = [QwikHelper shared];
    
    //call the api to get a list of restraurants
    [[[[QwikHttpObjc alloc]init:@"http://resttest2016.herokuapp.com/restaurants" httpMethod:HttpRequestMethodGet] addUrlParams:@{@"format" : @"json"}]getStringResponse:^(NSString * data, NSError * error, QwikHttpObjc * request) {
       
        //get the string response and parse it into a json array and then to a result array using QwikJson
        if(data)
        {
            NSArray * jsonArray = [NSArray fromJsonString:data];
            NSArray<Restaurant*> * results = [Restaurant arrayForJsonArray:jsonArray ofClass:[Restaurant class]];
            [UIAlertController showAlertWithTitle:@"Success" andMessage:[NSString stringWithFormat:@"Got %li",(long)results.count] from:self];
        }
    }];
}

-(IBAction)sendRequest:(id)sender
{
    [[[[QwikHttpObjc alloc]init:@"http://resttest2016.herokuapp.com/restaurants" httpMethod:HttpRequestMethodGet] addUrlParams:@{@"format" : @"json"}]getArrayResponse:^(NSArray * data, NSError * error, QwikHttpObjc * request) {
        
        //get the string response and parse it into a result array using QwikJson.
        //note that this time we used the array handler to get the results as an array of dictionaries rather
        //than needing to parse the string to a json array first.
        if(data)
        {
            NSArray * restaurants = [Restaurant arrayForJsonArray:data ofClass:[Restaurant class]];
            [UIAlertController showAlertWithTitle:@"Success" andMessage:[NSString stringWithFormat:@"Got %li",(long)restaurants.count] from:self];
        }
    }];
}

@end
