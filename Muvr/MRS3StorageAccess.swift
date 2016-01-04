import MuvrKit

///
/// Load models from cloud storage
/// and upload user data
///
/// Currently based on AWS S3
///
class MRS3StorageAccess: MRStorageAccessProtocol {

    let algo = "AWS4-HMAC-SHA256"
    let awsBucket = "muvr-user-data"
    let awsRegion = "eu-west-1"
    let awsService = "s3"
    let awsHost = "muvr-user-data.s3.amazonaws.com"
    let accessKey: String
    let secretKey: String
    
    
    var now: NSDate {
        return NSDate(timeIntervalSinceNow: Double(NSTimeZone.localTimeZone().secondsFromGMT))
    }

    var signingKey: HmacDigest {
        var key = AWSKey(secret: secretKey, region: awsRegion, service: awsService, onDate: now)
        
        func validKey() -> AWSKey {
            if NSDate().timeIntervalSinceDate(key.expiration) > 0 {
                key = AWSKey(secret: secretKey, region: awsRegion, service: awsService, onDate: now)
            }
            return key
        }
        
        return validKey().key
    }
    
    init(accessKey: String, secretKey: String) {
        self.accessKey = accessKey
        self.secretKey = secretKey
    }
    
    // create an HTTP request with the provided data
    internal func createRequest(method method: String, path: String, params: [String:String]? = nil, payload: NSData? = nil, date: NSDate? = nil, signingKey: HmacDigest? = nil) -> NSURLRequest {
        let now = date ?? NSDate(timeIntervalSinceNow: Double(NSTimeZone.localTimeZone().secondsFromGMT))
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
                return NSURLQueryItem(name: name, value: value)
            }
        }
        
        let request = NSMutableURLRequest(URL: urlBuilder.URL!)
        let payload = payload ?? NSData()
        let payloadDigest = DigestAlgorithm.SHA256.digest(payload.bytes, dataLength: payload.length)
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
        let signature = String(strToSign: stringToSign, algo: .SHA256, key: signingKey ?? self.signingKey)
        
        request.setValue("\(algo) Credential=\(credential),SignedHeaders=\(signedHeaders),Signature=\(signature)", forHTTPHeaderField: "Authorization")
    
        return request
    }
    
    ///
    /// upload the given ``data`` into remote ``path``
    ///
    func uploadFile(path: String, data: NSData, continuation: () -> Void) {
        let request = createRequest(method: "PUT", path: path, params: nil, payload: data)
        let task = NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: data) { data, response, error in
            guard let response = response as? NSHTTPURLResponse else { return }
            NSLog("-> \(response.statusCode)")
            if response.statusCode == 200 {
                continuation()
            }
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
    func downloadFile(path: String, continuation: NSURL? -> Void) {
        let request = createRequest(method: "GET", path: path)
        let task = NSURLSession.sharedSession().downloadTaskWithRequest(request) { url, response, error in
            guard let response = response as? NSHTTPURLResponse where response.statusCode == 200 else {
                continuation(nil)
                return
            }
            continuation(url)
        }
        task.resume()
    }
    
    ///
    /// download the remote file pointed by ``url``
    ///
    func downloadFile(url: NSURL, continuation: NSURL? -> Void) {
        guard let path = url.path else {
            continuation(nil)
            return
        }
        downloadFile(path, continuation: continuation)
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
        // add ending ``/`` if needed
        if prefix[prefix.endIndex.predecessor()] != "/" {
            prefix = "\(prefix)/"
        }
        
        let request = createRequest(method: "GET", path: "/", params: ["delimiter": "/", "prefix": prefix])
        
        // send request
        let task = NSURLSession.sharedSession().downloadTaskWithRequest(request) { url, response, error in
            guard let response = response as? NSHTTPURLResponse where response.statusCode == 200,
                  let url = url
            else {
                continuation(nil)
                return
            }
            let parser = XMLS3ListObjectsParser(url: url)
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

}

struct AWSKey {
    
    let key: HmacDigest
    let expiration: NSDate
    
    init(secret: String, region: String, service: String, onDate: NSDate) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd"

        let date = dateFormatter.stringFromDate(onDate)
        let dateKey = date.digest(.SHA256, key :"AWS4\(secret)")
        let dateRegionKey = region.digest(.SHA256, key : dateKey)
        let dateRegionServiceKey = service.digest(.SHA256, key: dateRegionKey)
        
        let signingKey = "aws4_request".digest(.SHA256, key: dateRegionServiceKey)
        let expirationDate = onDate.dateOnly.addDays(7)
        self.key = signingKey
        self.expiration = expirationDate
    }
}

/// Parses XML S3 ListObjects response
class XMLS3ListObjectsParser: NSObject, NSXMLParserDelegate {
    
    /// XMLStruct is
    ///
    /// <ListBucketResult>
    ///   <Contents>
    ///     <Key>file</Key>
    ///   </Contents>
    /// </ListBucketResult>
    ///
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
    
    init(url: NSURL) {
        parser = NSXMLParser(contentsOfURL: url)!
        super.init()
        parser.delegate = self
    }
    
    func parse() {
        parser.parse()
    }
    
    /// MARK : Parser delegate
    
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
