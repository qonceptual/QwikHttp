# QwikHttp

QwikHttp is a robust, yet lightweight and simple to use HTTP networking library. It allows you to customize every aspect
of your http requests within a single line of code, using a Builder style syntax to keep your code super clean.

QwikHttp is written in Swift, but can be used in both objective-c or swift projects. 

## Usage

Here are some example of how easy it is to use QwikHttp

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

    //url parameters
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

### Response Handlers
Response Handlers are super easy to use too. 

#### Typed Result Handlers
There are various Typed response handlers that correspond to the type of data You are expecting to get back. By letting the api know you want an array of JSON objects parsed into NSDictionaries, you can unload all this repetitive parsing logic and let the API do it.
```
    QwikHttp(urlString: "http://api.com", httpMethod: .get).dictionaryResponse{ (responseDictionary) -> Void in
        //the api's JSON response has been parsed into an NSDictionary for you, guaranteed!
        //so do whatever you want with the dictionary without needing to mess with the response directly
    }.send()
```
The following types are supported:
- Dictionary: parsed from JSON
- Array: also parsed from JSON
- String: parsed from the data response
- Data: the raw response data, can use used for binary responses

#### Error Handler
You may also include an error handler to get info on any error that may occur. This will get called if there is a problem sending your request, or if the NSUrlSession returns an error when making a request, if there is a problem parsing the response to the type desired by a typed result handler, or if the response contains a status code that doesn't equal 200 (success).

```
    QwikHttp(urlString: "http://api.com", httpMethod: .get).dictionaryResponse{ (responseDictionary) -> Void in}
        .errorResponse{ (errorResponse, error, statusCode) -> Void in
            //display the NSError data, giving you access to the raw response data parsed into a string
            //and the result status code to check for invalid permissions and prompt a login.
        }.send()
```
#### Pass / Fail Global Response Handler
You may also add a simple Yes/No global response handler within your send call that will get called whether the request
Succeeds or fails. This will allow you to perform any logic that should occur in either case, or if you don't need to do
any specific logic, except for check for failure.
```
QwikHttp(urlString: "http://api.com", httpMethod: .get).dictionaryResponse{ (responseDictionary) -> Void in }
    .send { (success) -> Void in
        //if success do x
    }
```

## Installation

QwikHttp is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "QwikHttp"
```

## Author

Logan Sease, logansease@qonceptual.com

## License

QwikHttp is available under the MIT license. See the LICENSE file for more info.
