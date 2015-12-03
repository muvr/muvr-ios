import MuvrKit

///
/// Load models from cloud storage
/// and upload user data
///
/// Currently based on AWS S3
///
class MRCloudStorage {
    
    let algo = "AWS4-HMAC-SHA256"
    let awsBucket = "muvr-user-data"
    let awsRegion = "eu-west-1"
    let awsService = "s3"
    let awsHost = "muvr-user-data.s3.amazonaws.com"
    
    let accessKey = "AKIAIOSFODNN7EXAMPLE"
    let secretKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    
    
    private var _signingKey: MRHmacDigest?
    private var _expirationDate: NSDate?
    
    private var signingKey: MRHmacDigest {
        if _expirationDate == nil || NSDate().timeIntervalSinceDate(_expirationDate!) > 0 {
            generateSigningKey()
        }
        return _signingKey!
    }
    
    private func generateSigningKey() {
        let now = NSDate(timeIntervalSinceNow: Double(NSTimeZone.localTimeZone().secondsFromGMT))
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd"
        
        let date = dateFormatter.stringFromDate(now)
        let dateKey = date.digest(.SHA256, key :"AWS4\(secretKey)")
        let dateRegionKey = awsRegion.digest(.SHA256, key : dateKey)
        let dateRegionServiceKey = awsService.digest(.SHA256, key: dateRegionKey)

        _signingKey = "aws4_request".digest(.SHA256, key: dateRegionServiceKey)
        _expirationDate = NSDate(timeInterval: 7 * 24 * 60 * 60, sinceDate: now)
    }
    
    func createRequest(method method: String, params: [String:String]?, payload: NSData?) -> NSURLRequest {
        let now = NSDate(timeIntervalSinceNow: Double(NSTimeZone.localTimeZone().secondsFromGMT))
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd"
        let simpleDate = dateFormatter.stringFromDate(now)
        
        dateFormatter.dateFormat = "YYYYMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        let fullDate = dateFormatter.stringFromDate(now)
        
        var queryStr = ""
        var url = "https://\(awsHost)"
        if let params = params {
            queryStr = params.map {k, v in return "k=v" }.sort().joinWithSeparator("&")
            url += "?\(queryStr)"
        }
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let payload = payload ?? NSData()
        let payloadDigest = MRDigestAlgorithm.SHA256.digest(payload.bytes, dataLength: payload.length)
        let payloadHash = String(digest: payloadDigest)
        request.HTTPMethod = method
        request.setValue(awsHost, forHTTPHeaderField: "Host")
        request.setValue("\(fullDate)", forHTTPHeaderField: "x-amz-date")
        request.setValue("\(payloadHash)", forHTTPHeaderField: "x-amz-content-sha256")
        
        let scope = "\(simpleDate)/\(awsRegion)/\(awsService)/aws4_request"
        let credential = "\(accessKey)/\(scope)"
        let signedHeaders = "host;x-amz-content-sha256;x-amz-date"
        let canonicalRequest = request.canonicalRequest(signedHeaders: signedHeaders, payloadHash: payloadHash)!
        let canonicalRequestHash = String(strToHash: canonicalRequest, algo: .SHA256)
        let stringToSign = "AWS4-HMAC-SHA256\n\(fullDate)\n\(scope)\n\(canonicalRequestHash)"
        let signature = String(strToSign: stringToSign, algo: .SHA256, key: signingKey)
        
        request.setValue("\(algo) Credential=\(credential),SignedHeaders=\(signedHeaders),Signature=\(signature)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    func listObjects() {
        let request = createRequest(method: "GET", params: nil, payload: nil)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            print("data:")
            if let data = data {
                print(String(data: data, encoding: NSUTF8StringEncoding))
            }
            print("response")
            print(response)
            print("error")
            print(error)
        }
        NSLog("\(request)")
        task.resume()
    }
}
