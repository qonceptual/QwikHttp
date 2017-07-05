# QwikHttp

QwikHttp is a robust, yet lightweight and simple to use HTTP networking library. It allows you to customize every aspect of your http requests within a single line of code, using a Builder style syntax to keep your code super clean.

What separates QwikHttp from other Networking Libraries is its: 
- light weight implementation 
- simple usage syntax
- use of generics and QwikJson for robust serialization and deserialization
- broad multi-platform support
- simple, yet robust loading indicator support
- response interceptors to provide a method to handle unauthorized responses and token refreshing with ease.

QwikHttp is written in Swift 3 but works (without generics) great with objective-c. It utilizes the most recent ios networking API, NSURLSession. QwikHttp is compatible with iOS 8+, tvOS, WatchOS 2 and OSX 10.9+. 
For a Swift 2 and objective-c compatible version, please see version 1.6.11

## Usage

Here are some example of how easy it is to use QwikHttp.

### A simple request

```swift
QwikHttp("https://api.com", httpMethod: .get).send()
```

### Parameters and Headers

You can set json, url or form encoded parameters
```swift
let params = ["awesome" : "true"]

//url parameters
QwikHttp("https://api.com", httpMethod: .get)
    .addUrlParameters(params)
    .send()

//form parameters
QwikHttp("https://api.com", httpMethod: .get)
    .addParameters(params)
    .setParameterType(.urlEncoded)
    .send()

//json parameters
QwikHttp("https://api.com", httpMethod: .get)
    .addParameters(params)
    .setParameterType(.json)
    .send()
```

You can set the body directly and add your own headers
```swift
let data =  UIImagePNGRepresentation(someImage);
let headers = ["Content-Type": "image/png"]
QwikHttp("https://api.com", httpMethod: .post)
    .setBody(data)
    .addHeaders(headers)
    .send()
```

### Generic

Note QwikHttp uses Generic completion handlers. Tell it what type you expect back in the response and it will handle your conversion.

The following Generic Types are supported by default. New types can be added by implementing the QwikDataConversion Protocol, which converts from NSData
- NSDictionary: Parsed from a JSON response
- NSString
- Bool: True if the request was successful
- NSNumber
- NSData
- Arrays: These are supported via using the type of the array contents and calling the array completion handler as described below. Types supporting Arrays by default are Strings, Dictionaries and QwikJson Objects
- For complex types, extend QwikJson to easily convert between dictionaries and complex objects and arrays ( see more below)

#### Typed Result Handlers

Depending on your needs, you may wish to call the objectHandler if you are expecting a single object, or the array handler. If you do not care, you can even use a simple (optional) boolean typed result handler.

#### Get Object
```swift
QwikHttp(url: "https://api.com", httpMethod: .get)
    .getResponse(NSDictionary.self,  { (result, error, request) -> Void in

    if let resultDictionary = result
    {
        //have fun with your JSON Parsed into a dictionary!
    }
    else if let resultError = error
    {
        //handle that error ASAP
    }
)}
```
#### Get Array
```swift
QwikHttp("https://api.com", httpMethod: .get)
    .getResponseArray(NSDictionary.self, { (result, error, request) -> Void in

    if let resultArray = result
    {
        //have fun with your JSON Parsed into an array of dictionaries
    }
    else if let resultError = error
    {
        //handle that error ASAP
    }
)}
```
#### Pass / Fail Boolean Response Handler

You may also use a simple Yes/No success response handler.
```swift
QwikHttp("https://api.com", httpMethod: .get)
    .send { (success) -> Void in

    //if success do x
}
```

#### More Detailed Response

Response objects are saved in the request object and available to use for more low level handling.
```swift
QwikHttp("https://api.com", httpMethod: .get)
    .getResponse(NSString.self,  { (result, error, request) -> Void in
    if let responseCode = request.response.responseCode
    {
        //check for 403 responses or whatever
    }
    if let responseString = request.responseString
    {
        //handle the response as a string directly
    }
    if let responseData = request.responseData
    {
        //handle the response as nsdata directly
    }
)}
```

#### Threading
You can tell QwikHttp if you'd prefer your response handlers to occur on the main thread or the background thread.
By default, all response handlers will be called on the Main Thread, however you can easily change this default or set it on a per request level.

```swift
QwikHttpConfig.setDefaultResponseThread(.Background)

QwikHttp("https://api.com", httpMethod: .get)
    .setResponseThread(.Main)
    .send()
```

### QwikJson
QwikJson, our Json serialization library, is now directly integrated with QwikHttp. This means that there is built in support for a range of complex model objects.

For full documentation on QwikJson, see our repo at https://github.com/qonceptual/QwikJson

Essentially, just subclass QwikJson in a complex model object and you can serialize and deserialize those model objects automatically with QwikHttp.

```swift
//declare your complex class with whatever properties
public Class MyModel : QwikJson
{
    var myProperty = "sweet"
}
```

Now you can pass and return QwikJson Objects to and from your RESTful API with ease!
```swift
let model = MyModel()

QwikHttp("https://api.com", httpMethod: .post)
    .setObject(model)
    .getResponse(MyModel.self,  { (result, error, request) -> Void in
    if let result as? Model
    {
        //you got a model back, with no parsing code!
    }
})
```

It even works with arrays
```swift
let model = MyModel()
let models = [model]

QwikHttp("https://api.com", httpMethod: .post)
    .setObjects(models)
    .getArrayResponse(MyModel.self, { (results, error, request) -> Void in
    if let modelArray = results as? [Model]
    {
        //you got an array of models back, with no parsing code!
    }
})
```

### Loading Indicators

By using the QwikHttpLoadingIndicatorDelegate protocol, you can provide an interface for QwikHttp to show and hide loading indicators during your http requests, allowing you to use any indicator you'd like, but allowing you to set it up and let QwikHttp handle it.

Once the default indicator delegate is set to QwikHttpConfig, Simply call the setLoadingTitle Method on your QwikHttp object and an indicator will automatically show when your request is running and hide when it completes

```swift
QwikHttp("https://api.com", httpMethod: .get)
    .setLoadingTitle("Loading")
    .send()
```

You can set the default title for the loading indicator, passing a nil title will keep it hidden (this is the default behavior), passing a string, even an empty one will make your indicator show and hide automatically by default
```swift
//hide the indicator by default
QwikHttpConfig.setDefaultLoadingTitle(nil)

//show the indicator with no title by default
QwikHttpConfig.setDefaultLoadingTitle("")
```

#### QwikHttpLoadingIndicator Delegate
QwikHttp will allow you to easily use your own loading indicator class by setting the QwikHttpLoadingIndicatorDelegate on QwikHttpConfig. You can do this to use cool indicators like MBProgressHUD or SwiftSpinner but let QwikHttp handle showing and hiding them so you don't have to.

The example below shows using a singleton helper class to handle your indicators, but this could be done in your app delegate, data service class, or within a view controller.
```swift
import SwiftSpinner
public class QwikHelper :  QwikHttpLoadingIndicatorDelegate
{
    public class func shared() -> QwikHelper {
    struct Singleton {
        static let instance = QwikHelper()
    }

    QwikHttpConfig.loadingIndicatorDelegate = Singleton.instance
        return Singleton.instance
    }

    @objc public func showIndicator(title: String!)
    {
        SwiftSpinner.show(title)
    }

    @objc public func hideIndicator()   
    {
        SwiftSpinner.hide()
    }
}
```

### Standard Headers
Configure the requests to all send a set of stanard headers without the need to explicitly send them on every request
```
QwikHttpConfig.standardHeaders = ["api_key" : "123123" ]
```

Easily remove the standard headers on particlar requests
```
QwikHttp("http://test.com", httpMethod: .get)
    .setAvoidStandardHeaders(true).run()
```

### Response & Request Interceptors
QwikHttp allows you to set a response interceptor that can selectively be called before each response is returned. Using this interceptor, you can do cool things like alter your responses in some way, or even cleanly handle unauthorized responses, allowing you to refresh an oAuth token or show the login screen under certain conditions.

You may also use a Request Interceptor to intercept requests before they are even sent. This could allow you to detect that a token is expired or that an action is not authorized before even sending your request.

Note that interceptors can be disabled on a per request basis
```swift
public class QwikHelper : QwikHttpResponseInterceptor, QwikHttpRequestInterceptor
{
    public class func shared() -> QwikHelper {
    struct Singleton {
        static let instance = QwikHelper()
    }
    QwikHttpConfig.responseInterceptor = Singleton.instance
        return Singleton.instance
    }

    @objc public func shouldInterceptResponse(response: NSURLResponse!) -> Bool
    {
        //TODO check for an unautorized response and return true if so
        return false
    }

    @objc public func interceptResponse(request : QwikHttp!, handler: (NSData?, NSURLResponse?, NSError?) -> Void)
    {
        //TODO check to see if response means that the token must be refreshed
        //if the token needs refreshing, refresh it- then save the new token to your auth service
        //now update the auth header in the QwikHttp request and reset and run it again.
        //call the handler with the results of the new request.
    }

    public func shouldInterceptRequest(request: QwikHttp!) -> Bool
    {
        //check for an expired token date on your current token
        return true
    }

    public func interceptRequest(request : QwikHttp!,  handler: (NSData?, NSURLResponse?, NSError?) -> Void)
    {
        //TODO refresh your token, restart the request
        //update the auth headers with the new token
        request.getResponse(NSData.self) { (data, error, request) -> Void! in
        handler(data,request.response,error)
    }
}
```

### Logging
You can easily view request level information from your http requests with the request.printDebugInfo() command.
This will result in something like this in your debugger
```
----- QwikHttp Request -----
POST to https://www.server.com/api/oauth/token/
HEADERS:
Content-Type: application/x-www-form-urlencoded
BODY:
grant_type=password&password=Password
RESPONSE: 200
{"access_token": "AXr4YoEAqwvrFz3BeAJZPKWf4z7Zkz"}
```
You may also set a default logging level on QwikHttpConfig so that debug information is printed by default. The levels are:
- error (Default) which will print a debug statement any time there is an error
- request: which will print a debug statement for every request
- debug: which will do the above plus print debug, low level info during the request process
- none: turn off logging


### Retain it and re run it
since QwikHttp is an object, you can hold on to it, pass it around and run it again!

```swift

var qwikHttp : QwikHttp
func setup()
{
    let self.qwikHttp = QwikHttp("https://api.com", httpMethod: .get)
    run(self.qwikHttp)

    //run it again after some delay
    NSThread.sleep(1000)
    self.qwikHttp.reset()
    run(self.qwikHttp)
}

func run(qwikHttp: QwikHttp)
{
    qwikHttp.send()
}

```
This also means that if you don't want to use the inline, builder style syntax, you don't have to!
```swift
let self.qwikHttp = QwikHttp("https://api.com", httpMethod: .get)
self.qwikHttp.addParams([:])
self.qwikHttp.addHeaders([:])
self.qwikHttp.run()
```

## More Optional Configuration

### Set time out and cache Policy per request

```swift
qwikHttp.setTimeOut(200)
qwikHttp.setCachePolicy(NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData)
qwikHttp.setResponseThread(.Background)
```


### Set Default Behaviors

Set for all your requests unless overwritten
```swift
QwikHttpConfig.defaultTimeOut = 300
QwikHttpConfig.defaultParameterType = .FormEncoded
QwikHttpConfig.defaultLoadingTitle = "Loading"
QwikHttpConfig.defaultCachePolicy = .ReloadIgnoringLocalCacheData
QwikHttpConfig.setDefaultResponseThread(.Background)
```

## Objective C

QwikHttp is compatible with objective-c by importing its objective-c class file. The objective c version of QwikHttp supports most of what the Swift version supports, except for Generics.
Instead of using generic type handlers, you may use the boolean handler or a string, data, dictionary or array (of dictionaries) handler and then utilize QwikJson to deserialize your objects if necessary.

```objective-c
#import "QwikHttp-Swift.h"

@implementation ObjcViewController

-(IBAction)sendRequest:(id)sender
{
    [[[[QwikHttp alloc]init:@"https://resttest2016.herokuapp.com/restaurants" httpMethod:HttpRequestMethodGet] 
        addUrlParams:@{@"format" : @"json"}]
        getArrayResponse:^(NSArray * results, NSError * error, QwikHttp * request) {

        if(results)
        {
            NSArray * restaurants = [Restaurant arrayForJsonArray:data ofClass:[Restaurant class]];
            [UIAlertController showAlertWithTitle:@"Success" andMessage:[NSString stringWithFormat:@"Got %li",(long)restaurants.count] from:self];
        }
    }];
}
```


## Installation

### Pods
QwikHttp is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "QwikHttp"
```

## Swift compatibility errors

If you experience this build error and you have already run Edit -> Convert -> to current Swift syntax, try adding the following to your podfile
"Use Legacy Swift Language Version” (SWIFT_VERSION) is required to be configured correctly..."
- Select the Pods project from your explorer in XCode
- Select the QwikHttp target
- Under project settings, find the LEGACY SWIFT VERSION, set it to No. Even if it is already set, set it again.


## Further Notes

Also, checkout the SeaseAssist pod for a ton of great helpers to make writing your iOS code even simpler!
https://github.com/logansease/SeaseAssist

## Author

Logan Sease, lsease@gmail.com

If you use and enjoy QwikHttp, I would LOVE to hear from you. I am very excited about this project and would love some feedback.

## License

QwikHttp is available under the MIT license. See the LICENSE file for more info.
