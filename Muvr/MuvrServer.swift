import Foundation

///
/// Adds the response negotiation
///
extension Request {
    
    func responseAsResult<A, U>(f: Result<A> -> U, completionHandler: (JSON) -> A) -> Void {
        
        func tryCompleteFromCache(error: NSError, request: NSURLRequest, f: Result<A> -> U, completionHandler: (JSON) -> A) {
            
            if request.HTTPMethod?.lowercaseString != "get" {
                NSLog("--- Non-GET cannot be cached %@.", request.URLString)
                f(Result.error(error))
                
                return
            }
            
            if let x = NSURLCache.sharedURLCache().cachedResponseForRequest(request) {
                // we have a cached response
                let s = NSString(data: x.data, encoding: NSUTF8StringEncoding)
                NSLog("--- Completed %@ from cache %@.", request.URLString, s!)
                var error: NSError? = nil
                let json = JSON(data: x.data, options: NSJSONReadingOptions.AllowFragments, error: &error)
                f(Result.value(completionHandler(json)))
            } else {
                NSLog("--- No cache value for %@.", request.URLString)
                f(Result.error(error))
            }
        }
        
        if true {
            responseSwiftyJSON { (request, response, json, error) -> Void in
                if let x = response {
                    // we have a valid response
                    let statusCodeFamily = x.statusCode / 100
                    if statusCodeFamily == 1 || statusCodeFamily == 2 || statusCodeFamily == 3 {
                        // 1xx, 2xx, 3xx responses are success responses
                        let val = completionHandler(json)
                        f(Result.value(val))
                    } else {
                        // 4xx responses are errors, but do not mean that the server is broken
                        let userInfo = [NSLocalizedDescriptionKey : json.stringValue]
                        let err = NSError(domain: "com.eigengo.lift", code: x.statusCode, userInfo: userInfo)
                        NSLog("4xx %@ -> %@", request, x)
                        f(Result.error(err))
                    }
                    if statusCodeFamily == 5 {
                        NSLog("5xx %@ -> %@", request, x)
                        // we have 5xx responses. this counts as server error.
                    }
                } else if let x = error {
                    // we don't have a responses, and we have an error
                    NSLog("--- %@ -> %@", request.URLString, x.localizedDescription)
                    
                    if x.domain == NSURLErrorDomain {
                        // unreachable server
                    } else {
                        // just server failure
                    }
                    
                    tryCompleteFromCache(x, request, f, completionHandler)
                }
            }
        } else {
            tryCompleteFromCache(NSError.errorWithMessage("Server unavailable", code: 999), request, f, completionHandler)
        }
    }
    
}

///
/// Lift server connection
///
public class MuvrServer {
    
    ///
    /// Singleton instance of the LiftServer. The instances are stateless, so it is generally a
    /// good idea to take advantage of the singleton
    ///
    public class var sharedInstance: MuvrServer {
        struct Singleton {
            static let instance = MuvrServer()
        }
        
        return Singleton.instance
    }
    
    ///
    /// The connection manager's configuration
    ///
    private let manager = Manager(configuration: {
        var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        configuration.requestCachePolicy = NSURLRequestCachePolicy.UseProtocolCachePolicy
        configuration.timeoutIntervalForRequest = NSTimeInterval(5) // default timeout
        
        configuration.HTTPAdditionalHeaders = {
            // Accept-Encoding HTTP Header; see http://tools.ietf.org/html/rfc7230#section-4.2.3
            let acceptEncoding: String = "gzip;q=1.0,compress;q=0.5"
            
            // Accept-Language HTTP Header; see http://tools.ietf.org/html/rfc7231#section-5.3.5
            let acceptLanguage: String = {
                var components: [String] = []
                for (index, languageCode) in enumerate(NSLocale.preferredLanguages()) {
                    let q = 1.0 - (Double(index) * 0.1)
                    components.append("\(languageCode);q=\(q)")
                    if q <= 0.5 {
                        break
                    }
                }
                
                return join(",", components)
                }()
            
            // User-Agent Header; see http://tools.ietf.org/html/rfc7231#section-5.5.3
            let userAgent: String = "org.eigengo.Lift (iOS)"
            
            return ["Accept-Encoding": acceptEncoding,
                "Accept-Language": acceptLanguage,
                "User-Agent": userAgent]
            }()
        
        return configuration
        }()
    )
    private let isoDateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter
        }()
    
    private var baseUrlString: String = MuvrUserDefaults.muvrServerUrl
    
    func setBaseUrlString(baseUrlString: String) -> Bool {
        if self.baseUrlString == baseUrlString { return false }
        
        self.baseUrlString = baseUrlString
        return true
    }
    
    ///
    /// Body is either JSON structure, Text or NSData
    ///
    private enum Body {
        case Json(params: [String : AnyObject])
        case Data(data: NSData)
    }
    
    ///
    /// Make a request to the Lift server
    ///
    private func request(req: MuvrServerRequestConvertible, body: Body? = nil) -> Request {
        let lsr = req.Request
        switch body {
        case let .Some(Body.Json(params)):
            let encoding = lsr.method == .GET ? ParameterEncoding.URL : ParameterEncoding.JSON
            return manager.request(lsr.method, baseUrlString + lsr.path, parameters: params, encoding: encoding)
        case let .Some(Body.Data(data)): return manager.upload(URLRequest(lsr.method, baseUrlString + lsr.path), data: data)
        case .None: return manager.request(lsr.method, baseUrlString + lsr.path, parameters: nil, encoding: ParameterEncoding.URL)
        }
    }
    
    func exerciseSessionPayload(payload: ExerciseSessionPayload, f: Result<String> -> Void) -> Void {
        request(MuvrServerURLs.exerciseSessionPayload(), body: .Json(params: payload.marshal()))
            .responseAsResult(f) { json in return json.stringValue }
    }
}
