import MuvrKit

///
/// Load models from cloud storage
/// and upload user data
///
/// Currently based on AWS S3
///
class MRS3StorageAccess: MRCloudStorageAccessProtocol {
    
    let algo = "AWS4-HMAC-SHA256"
    let awsBucket = "muvr-user-data"
    let awsRegion = "eu-west-1"
    let awsService = "s3"
    let awsHost = "muvr-user-data.s3.amazonaws.com"

    let accessKey = "AKIAIOSFODNN7EXAMPLE"
    let secretKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    
    
    // do not use these properties directly
    // instead used the computed property ``signingKey``
    private var _signingKey: MRHmacDigest?
    private var _expirationDate: NSDate?
    
    // makes sure the signing key is not expired
    private var signingKey: MRHmacDigest {
        if _expirationDate == nil || NSDate().timeIntervalSinceDate(_expirationDate!) > 0 {
            generateSigningKey()
        }
        return _signingKey!
    }
    
    // generates a valid signing key from the secret key
    private func generateSigningKey() {
        let now = NSDate(timeIntervalSinceNow: Double(NSTimeZone.localTimeZone().secondsFromGMT))
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd"
        
        let date = dateFormatter.stringFromDate(now)
        let dateKey = date.digest(.SHA256, key :"AWS4\(secretKey)")
        let dateRegionKey = awsRegion.digest(.SHA256, key : dateKey)
        let dateRegionServiceKey = awsService.digest(.SHA256, key: dateRegionKey)
        
        _signingKey = "aws4_request".digest(.SHA256, key: dateRegionServiceKey)
        _expirationDate = NSDate(timeInterval: 7 * 24 * 60 * 60, sinceDate: now.dateOnly)
    }
    
    // create an HTTP request with the provided data
    private func createRequest(method method: String, path: String, params: [String:String]? = nil, payload: NSData? = nil) -> NSURLRequest {
        let now = NSDate(timeIntervalSinceNow: Double(NSTimeZone.localTimeZone().secondsFromGMT))
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd"
        let simpleDate = dateFormatter.stringFromDate(now)
        
        dateFormatter.dateFormat = "YYYYMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        let fullDate = dateFormatter.stringFromDate(now)
        
        let urlBuilder = NSURLComponents()
        urlBuilder.scheme = "https"
        urlBuilder.host = awsHost
        urlBuilder.path = path
        if let params = params {
            urlBuilder.queryItems = params.flatMap { name, value in
                // URLQueryAllowedCharacterSet doesn't escape ``/``
                // (``/`` is escaped to ``%2f`` which is a format flag for NSLog so it displays as ``0.000000`` in the logs)
                let v = value.stringByReplacingOccurrencesOfString("/", withString: "%2f")
                return NSURLQueryItem(name: name, value: v)
            }
        }
        
        let request = NSMutableURLRequest(URL: urlBuilder.URL!)
        let payload = payload ?? NSData()
        let payloadDigest = MRDigestAlgorithm.SHA256.digest(payload.bytes, dataLength: payload.length)
        let payloadHash = String(digest: payloadDigest)
        request.HTTPMethod = method
        request.HTTPBody = payload
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
    
    ///
    /// list the remote files located at ``path``
    ///
    func listFiles(path: String, continuation: [NSURL]? -> Void) {
        // skip initial ``/`` if needed
        var prefix = path
        if prefix[prefix.startIndex] == "/" {
            prefix = prefix.substringFromIndex(prefix.startIndex.successor())
        }
        
        let request = createRequest(method: "GET", path: "/", params: ["delimiter": "/", "prefix": prefix], payload: nil)
        
        // send request
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
           // NSLog("response:\n\(response)")
            guard let response = response as? NSHTTPURLResponse where response.statusCode == 200,
                let data = data
                else {
                    continuation(nil)
                    return
            }
            NSLog("data:\n\(String(data: data, encoding: NSUTF8StringEncoding))")
            let parser = XMLS3ListObjectsParser(data: data)
            parser.parse()
            let baseUrl = NSURL(string: "https://\(self.awsHost)/")
            let modelUrls = parser.objects.flatMap { filename in
                return NSURL(string: filename, relativeToURL: baseUrl)
            }
            continuation(modelUrls)
        }
        task.resume()
    }
    
    ///
    /// list the remote files located at ``url``
    ///
    func listFiles(url: NSURL, continuation: [NSURL]? -> Void) {
        guard let path = url.path else {
            continuation(nil)
            return
        }
        listFiles(path, continuation: continuation)
    }
    
    ///
    /// upload the given ``data`` into remote ``path``
    ///
    func uploadFile(path: String, data: NSData, continuation: () -> Void) {
        let request = createRequest(method: "PUT", path: path, params: nil, payload: data)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            NSLog("response:\n\(response)")
            guard let response = response as? NSHTTPURLResponse where response.statusCode == 200 else {
                return
            }
            if let data = data { NSLog("data:\n\(String(data: data, encoding: NSUTF8StringEncoding))") }
            continuation()
        }
        task.resume()
    }
    
    ///
    /// upload the given ``data`` into remote ``url``
    ///
    func uploadFile(url: NSURL, data: NSData, continuation: () -> Void) {
        guard let path = url.path else { return }
        uploadFile(path, data: data, continuation: continuation)
    }
    
    
    ///
    /// download the remote file pointed by ``path``
    ///
    func downloadFile(path: String, continuation: NSData? -> Void) {
        let request = createRequest(method: "GET", path: path)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            NSLog("response:\n\(response)")
            NSLog("data:\n\(String(data: data!, encoding: NSUTF8StringEncoding))")
            guard let response = response as? NSHTTPURLResponse where response.statusCode == 200 else {
                continuation(nil)
                return
            }
            continuation(data)
        }
        task.resume()
    }
    
    ///
    /// download the remote file pointed by ``url``
    ///
    func downloadFile(url: NSURL, continuation: NSData? -> Void) {
        guard let path = url.path else {
            continuation(nil)
            return
        }
        downloadFile(path, continuation: continuation)
    }
}

class XMLS3ListObjectsParser: NSObject, NSXMLParserDelegate {
    
    enum XMLNode: String {
        case ListBucketResult
        case Contents
        case Key
        
        func prev() -> XMLNode? {
            switch (self) {
            case .ListBucketResult: return nil
            case .Contents: return .ListBucketResult
            case .Key: return .Contents
            }
        }
        
        func next() -> XMLNode? {
            switch (self) {
            case .ListBucketResult: return .Contents
            case .Contents: return .Key
            case .Key: return nil
            }
        }
    }
    
    private(set) var objects: [String] = []
    private var currentNode: XMLNode? = nil
    private let parser: NSXMLParser
    
    init(data: NSData) {
        parser = NSXMLParser(data: data)
        super.init()
        parser.delegate = self
    }
    
    func parse() {
        parser.parse()
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard let currentNode = currentNode,
            let endNode = XMLNode(rawValue: elementName) where endNode == currentNode else { return }
        self.currentNode = currentNode.prev()
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        guard let startNode = XMLNode(rawValue: elementName) else { return }
        if let nextNode = currentNode?.next() where nextNode != startNode { return }
        self.currentNode = startNode
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        guard let currentNode = currentNode where currentNode == .Key else { return }
        objects.append(string)
    }
    
}
