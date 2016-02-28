# QwikHttp

QwikHttp is a robust, yet lightweight and simple to use HTTP networking library. It allows you to customize every aspect
of your http requests within a single line of code, using a Builder style syntax to keep your code super clean.

QwikHttp is written in Swift, but can be used in both objective-c or swift projects. It utilizes the most recent ios networking api, NSURLSession.

## Usage

Here are some example of how easy it is to use QwikHttp.

###A simple request

```
    QwikHttp(urlString: "http://api.com", httpMethod: .get).send()
```

###Parameters and Headers

You can set json, url or form encoded parameters
```
    let params = ["awesome" : "true"]

    //url parameters
    QwikHttp(urlString: "http://api.com", httpMethod: .get).addUrlParameters(params).send()

    //form parameters
    QwikHttp(urlString: "http://api.com", httpMethod: .get).addParameters(params).setParameterType(.urlEncoded).send()

    //json parameters
    QwikHttp(urlString: "http://api.com", httpMethod: .get).addParameters(params).setParameterType(.json).send()
```

You can set the body directly and add your own headers
```
    let data =  UIImagePNGRepresentation(someImage);
    let headers = ["Content-Type": "image/png"]
    QwikHttp(urlString: "http://api.com", httpMethod: .post).setBody(data).addHeaders(headers).send()
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

        QwikHttp(urlString: "http://api.com", httpMethod: .get).getResponse(NSDictionary.self, handler: { (result, error, request) -> Void in
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

        QwikHttp(urlString: "http://api.com", httpMethod: .get).getResponseArray(NSDictionary.self, handler: { (result, error, request) -> Void in
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
QwikHttp(urlString: "http://api.com", httpMethod: .get)
    .send { (success) -> Void in
        //if success do x
    }
```

#### More Detailed Response

Response objects are saved in the request object and available to use for more low level handling.
```
QwikHttp(urlString: "http://api.com", httpMethod: .get).getResponse(NSString.self, handler: { (result, error, request) -> Void in
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
Response Handlers are always called on the main thread. This means that you don't have to worry about explicity running on the main thread in your completion handlers, which makes your code more managable. If, however you are expecting that code running in your response handlers is still running on a background thread, you will be incorrect. Make sure you explicitly run on the background thread if that is the behavior you desire.


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

QwikHttp(urlString: "http://api.com", httpMethod: .post).setObject(model).getResponse(MyModel.self, handler: { (result, error, request) -> Void in
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

QwikHttp(urlString: "http://api.com", httpMethod: .post).setObjects(models).getArrayResponse(MyModel.self, handler: { (results, error, request) -> Void in
    if let modelArray = results as? [Model]
    {
        //you got an array of models back, with no parsing code!
    }
})
```

### Loading Indicators

Swift Spinner (https://github.com/icanzilb/SwiftSpinner) is integrated directly into QwikHttp providing a beautiful looking loading indicator with no extra code.

Simply call the setLoadingTitle Method on your QwikHttp object and an indicator will automatically show when your request is running and hide when complete

```
QwikHttp(urlString: "http://api.com", httpMethod: .get).setLoadingTitle("Loading").send()
```

You can set the default title for the loading indicator, passing a nil title will keep it hidden (this is the default behavior), passing a string, even an empty one will make your indicator show and hide automatically by default
```
//hide the indicator by default
QwikHttpDefaults.setDefaultLoadingTitle(nil)

//show the indicator with no title by default
QwikHttpDefaults.setDefaultLoadingTitle("")
```

### Retain it and re run it
since QwikHttp is an object, you can hold on to it, pass it around and run it again!

```
    func setup()
    {
        let self.qwikHttp = QwikHttp(urlString: "http://api.com", httpMethod: .get)
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
    let self.qwikHttp = QwikHttp(urlString: "http://api.com", httpMethod: .get)
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
QwikHttpDefaults.setDefaultTimeOut(300)
QwikHttpDefaults.setDefaultParameterType(.form)
QwikHttpDefaults.setDefaultLoadingTitle("Loading")
QwikHttpDefaults.setDefaultCachePolicy(.ReloadIgnoringLocalCacheData)
```

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
