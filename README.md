# QwikHttp

QwikHttp is a robust, yet lightweight and simple to use HTTP networking library. It allows you to customize every aspect
of your http requests within a single line of code, using a Builder style syntax to keep your code super clean.

QwikHttp is written in Swift, but can be used in both objective-c or swift projects. It utilizes the most recent ios networking api, NSURLSession.

## Usage

Here are some example of how easy it is to use QwikHttp.

###A simple request

```
    QwikHttp<NSString>(urlString: "http://api.com", httpMethod: .get).send()
```

###Parameters and Headers

You can set json, url or form encoded parameters
```
    let params = ["awesome" : "true"]

    //url parameters
    QwikHttp<String>(urlString: "http://api.com", httpMethod: .get).addUrlParameters(params).send()

    //form parameters
    QwikHttp<String>(urlString: "http://api.com", httpMethod: .get).addParameters(params).setParameterType(.urlEncoded).send()

    //json parameters
    QwikHttp<String>(urlString: "http://api.com", httpMethod: .get).addParameters(params).setParameterType(.json).send()
```

You can set the body directly and add your own headers
```
    let data =  UIImagePNGRepresentation(someImage);
    let headers = ["Content-Type": "image/png"]
    QwikHttp<String>(urlString: "http://api.com", httpMethod: .post).setBody(data).addHeaders(headers).send()
```

###Generic

Note QwikHttp<> is Generic. Tell it what type you expect back in the response and it will handle your conversion.

The following Generic Types are supported by default. New types can be added by implementing the QwikConversion Protocol, which converts from NSData
- NSDictionary: Parsed from a JSON response
- NSString
- Bool: True if the request was successful
- NSNumber
- NSData
- Arrays: These are supported via using the type of the array contents and calling the array completion handler as described below.
- For complex types, extend QwikJson to easily convert between dictionaries and complex objects and arrays


#### Typed Result Handlers

Depending on your needs, you may wish to call the objectHandler if you are expecting a single object, or the array handler. If you do not care, you can even use
A simple (optional) boolean typed result handler.

#### Get Object

        QwikHttp<NSDictionary>(urlString: "http://api.com", httpMethod: .get).getResponse({ (result, error, request) -> Void in
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

        QwikHttp<NSDictionary>(urlString: "http://api.com", httpMethod: .get).getResponse({ (result, error, request) -> Void in
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

You may also add a simple Yes/No global response handler within your send call that will get called whether the request
Succeeds or fails. 
```
QwikHttp<String>(urlString: "http://api.com", httpMethod: .get)
    .send { (success) -> Void in
        //if success do x
    }
```

#### More Detailed Response

Response objects are saved in the request object and available to use for more low level handling.
```
QwikHttp<NSDictionary>(urlString: "http://api.com", httpMethod: .get).getResponse({ (result, error, request) -> Void in
    if let responseCode = request.response.responseCode
    {
        //check for 403 responses or whatever
    }
    if let responseString = request.responseString
    {
        //handle the response as a string directly
    }
)}
```

#### Threading
Response Handlers are always called on the main thread. This means that you don't have to worry about explicity running on the main thread in your completion handlers, which makes your more managable. If, however you are expecting that code running in your response handlers is still running on a background thread, you will be incorrect. Make sure you explicitly run on the background thread if that is the behavior you desire.


### Retain it and re run it
since QwikHttp is an object, you can hold on to it, pass it around and run it again!

```
    func setup()
    {
        let self.qwikHttp = QwikHttp<String>(urlString: "http://api.com", httpMethod: .get)
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
    let self.qwikHttp = QwikHttp<NSData>(urlString: "http://api.com", httpMethod: .get)
    self.qwikHttp.addParams([:])
    self.qwikHttp.addHeaders([:])
    self.qwikHttp.run()
```

### Set default time out and cache Policy

```
    qwikHttp.setTimeOut(200)
    qwikHttp.setCachePolicy(NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData)
```

## Installation

###Pods
QwikHttp is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "QwikHttp"
```

###Or add the source.
If you have problems using the pod, or don't want to use cocoaPods, it will be as simple as adding the source from the project into your own. Currently, that is only one file (QwikHttp.swift)

There are no external dependencies!

## Further Notes

Another essential part of restful requests is parsing the response dictionaries (JSON) into our model objects, and passing model objects into our requests.
Consider using QwikJson in combination with this library to complete your toolset.
https://github.com/qonceptual/QwikJson

Also, checkout the SeaseAssist pod for a ton of great helpers to make writing your iOS code even simpler!
https://github.com/logansease/SeaseAssist

## Author

Logan Sease, logansease@qonceptual.com

## License

QwikHttp is available under the MIT license. See the LICENSE file for more info.
