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
    QwikHttpConfig.responseInterceptor = [QwikHelper shared];
    
    //call the api to get a list of restraurants
    [[[[QwikHttp alloc]init:@"https://resttest2016.herokuapp.com/restaurants" httpMethod:HttpRequestMethodGet] addUrlParams:@{@"format" : @"json"}]getStringResponse:^(NSString * data, NSError * error, QwikHttp * request) {
       
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
    [[[[QwikHttp alloc]init:@"https://resttest2016.herokuapp.com/restaurants" httpMethod:HttpRequestMethodGet] addUrlParams:@{@"format" : @"json"}]getStringResponse:^(NSString * data, NSError * error, QwikHttp * request) {
        
        //get the string response and parse it into a json array and then to a result array using QwikJson
        if(data)
        {
            NSArray * jsonArray = [NSArray fromJsonString:data];
            NSArray<Restaurant*> * results = [Restaurant arrayForJsonArray:jsonArray ofClass:[Restaurant class]];
            [UIAlertController showAlertWithTitle:@"Success" andMessage:[NSString stringWithFormat:@"Got %li",(long)results.count] from:self];
        }
    }];
}

@end
