# QwikHttp

QwikHttp is a robust, yet lightweight and simple to use HTTP networking library. It allows you to customize every aspect of your http requests within a single line of code, using a Builder style syntax to keep your code super clean.

What separates QwikHttp from other Networking Libraries is its: 
- light weight implementation 
- simple usage syntax
- use of generics and QwikJson for robust serialization and deserialization
- broad multi-platform support
- simple, yet robust loading indicator implementation
- response interceptors provide a method to handle unauthorized responses and token refreshing with ease.

QwikHttp is written in Swift but works (without generics) great with objective-c. It utilizes the most recent ios networking API, NSURLSession. QwikHttp is compatible with iOS 7+, tvOS, WatchOS 2 and OSX 10.8+. 

## Usage

Here are some example of how easy it is to use QwikHttp.

###A simple request

```
    QwikHttp("http://api.com", httpMethod: .Get).send()
```

###Parameters and Headers

You can set json, url or form encoded parameters
```
    let params = ["awesome" : "true"]

    //url parameters
    QwikHttp("http://api.com", httpMethod: .Get).addUrlParameters(params).send()

    //form parameters
    QwikHttp("http://api.com", httpMethod: .Get).addParameters(params).setParameterType(.urlEncoded).send()

    //json parameters
    QwikHttp("http://api.com", httpMethod: .Get).addParameters(params).setParameterType(.json).send()
```

You can set the body directly and add your own headers
```
    let data =  UIImagePNGRepresentation(someImage);
    let headers = ["Content-Type": "image/png"]
    QwikHttp("http://api.com", httpMethod: .Post).setBody(data).addHeaders(headers).send()
```

###Generic

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

Depending on your needs, you may wish to call the objectHandler if you are expecting a single object, or the array handler. If you do not care, you can even use
A simple (optional) boolean typed result handler.

#### Get Object

        QwikHttp(url: "http://api.com", httpMethod: .Get).getResponse(NSDictionary.self,  { (result, error, request) -> Void in
            if let resultDictionary = result
            {
                //have fun with your JSON Parsed into a dictionary!
            }
            else if let resultError = error
            {
                //handle that error ASAP
            }
        )}

#### Get Array

        QwikHttp("http://api.com", httpMethod: .Get).getResponseArray(NSDictionary.self, { (result, error, request) -> Void in
            if let resultArray = result
            {
                //have fun with your JSON Parsed into an array of dictionaries
            }
            else if let resultError = error
            {
                //handle that error ASAP
            }
        )}

#### Pass / Fail Boolean Response Handler

You may also use a simple Yes/No success response handler.
```
QwikHttp("http://api.com", httpMethod: .Get)
    .send { (success) -> Void in
        //if success do x
    }
```

#### More Detailed Response

Response objects are saved in the request object and available to use for more low level handling.
```
QwikHttp("http://api.com", httpMethod: .Get).getResponse(NSString.self,  { (result, error, request) -> Void in
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
You can tell QwikJson if you'd prefer your response handlers to occur on the main thread of the background thread.
By default, all response handlers will be called on the Main Thread, however you can easily change this default and set it on a per request level.

```objective-c
QwikHttpConfig.setDefaultResponseThread(.Background)
qwikHttp.setResponseThread(.Main)
```

### QwikJson
QwikJson, our Json serialization library, is now directly integrated with QwikHttp. This means that there is built in support for a range of complex model objects.

For full documentation on QwikJson, see our repo at https://github.com/qonceptual/QwikJson

Essentially, just subclass QwikJson in a complex model object and you can serialize and deserialize those model objects automatically with QwikHttp.

```
//declare your complex class with whatever properties
public Class MyModel : QwikJson
{
    var myProperty = "sweet"
}
```

Now you can pass and return QwikJson Objects to and from your ReSTful API with ease!
```
let model = MyModel()

QwikHttp("http://api.com", httpMethod: .post).setObject(model).getResponse(MyModel.self,  { (result, error, request) -> Void in
    if let result as? Model
    {
        //you got a model back, with no parsing code!
    }
})
```

It even works with arrays
```
let model = MyModel()
let models = [model]

QwikHttp("http://api.com", httpMethod: .post).setObjects(models).getArrayResponse(MyModel.self, { (results, error, request) -> Void in
    if let modelArray = results as? [Model]
    {
        //you got an array of models back, with no parsing code!
    }
})
```

### Loading Indicators

Simply call the setLoadingTitle Method on your QwikHttp object and an indicator will automatically show when your request is running and hide when complete

```
QwikHttp("http://api.com", httpMethod: .Get).setLoadingTitle("Loading").send()
```

You can set the default title for the loading indicator, passing a nil title will keep it hidden (this is the default behavior), passing a string, even an empty one will make your indicator show and hide automatically by default
```
//hide the indicator by default
QwikHttpConfig.setDefaultLoadingTitle(nil)

//show the indicator with no title by default
QwikHttpConfig.setDefaultLoadingTitle("")
```

####Custom Loading Indicators
QwikHttp will allow you to easily use your own loading indicator class by setting the QwikHttpLoadingIndicatorDelegate on QwikHttpConfig. You can do this to use cool indicators like MBProgressHUD or SwiftSpinner but let QwikHttp handle showing and hiding them so you don't have to.

```swift
import SwiftSpinner
public class QwikHelper :  QwikHttpLoadingIndicatorDelegate
{
    public class func shared() -> QwikHelper {
        struct Singleton {
            static let instance = QwikHelper()
        }
        QwikHttpConfig.indicatorDelegate = Singleton.instance
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

###Response Interceptor
QwikHttp allows you to set a response interceptor that can selectively be called before each response is returned. Using this interceptor, you can do cool things like alter your responses in some way, or even cleanly handle unauthorized responses, allowing you to refresh an oAuth token or show the login screen under certain conditions.

```swift
public class QwikHelper : QwikHttpResponseInterceptor
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
        //now update the header in the QwikHttp request and reset and run it again. Pass in the 
        //call the handler with the results of the new request.
    }
}
```

### Retain it and re run it
since QwikHttp is an object, you can hold on to it, pass it around and run it again!

```
    func setup()
    {
        let self.qwikHttp = QwikHttp("http://api.com", httpMethod: .Get)
        run(self.qwikHttp)
        
        //run it again after some delay
        NSThread.sleep(1000)
        self.qwikHttp.reset()
        run(self.qwikHttp)
    }

    func run(qwikHttp: QwikHttp!)
    {
        qwikHttp.run()
    }

```
This also means that if you don't want to use the inline, builder style syntax, you don't have to!
```
    let self.qwikHttp = QwikHttp("http://api.com", httpMethod: .Get)
    self.qwikHttp.addParams([:])
    self.qwikHttp.addHeaders([:])
    self.qwikHttp.run()
```

## More Optional Configuration

### Set time out and cache Policy per request

```
    qwikHttp.setTimeOut(200)
    qwikHttp.setCachePolicy(NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData)
```


### Set Default Behaviors

Set for all your requests unless overwritten
```
QwikHttpConfig.defaultTimeOut = 300
QwikHttpConfig.defaultParameterType = .FormEncoded
QwikHttpConfig.defaultLoadingTitle = "Loading"
QwikHttpConfig.defaultCachePolicy = .ReloadIgnoringLocalCacheData
```

## Objective C
QwikHttp is compatible with objective-c by importing its objective-c class file. The objective c version of QwikHttp supports most of what the Swift version supports, except for Generics.
Instead of using generic type handlers, you may use the boolean handler or a string, data, dictionary or array (of dictionaries) handler and then utilize QwikJson to deserialize your objects if necessary.

```objective-c
#import "QwikHttp-Swift.h"

@implementation ObjcViewController

-(IBAction)sendRequest:(id)sender
{
    [[[[QwikHttpObjc alloc]init:@"http://resttest2016.herokuapp.com/restaurants" httpMethod:HttpRequestMethodGet] 
        addUrlParams:@{@"format" : @"json"}]
        getArrayResponse:^(NSArray * results, NSError * error, QwikHttpObjc * request) {

        if(results)
        {
            NSArray * restaurants = [Restaurant arrayForJsonArray:data ofClass:[Restaurant class]];
            [UIAlertController showAlertWithTitle:@"Success" andMessage:[NSString stringWithFormat:@"Got %li",(long)restaurants.count] from:self];
        }
    }];
}


## Installation

###Pods
QwikHttp is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "QwikHttp"
```

## Further Notes

Another essential part of restful requests is parsing the response dictionaries (JSON) into our model objects, and passing model objects into our requests.
Consider using QwikJson in combination with this library to complete your toolset.
https://github.com/qonceptual/QwikJson

Also, checkout the SeaseAssist pod for a ton of great helpers to make writing your iOS code even simpler!
https://github.com/logansease/SeaseAssist

## Author

Logan Sease, lsease@gmail.com

## License

QwikHttp is available under the MIT license. See the LICENSE file for more info.
