import Foundation

extension NSURLRequest {

    ///
    /// Returns the canonical request string for this NSURLRequest
    /// Canonical request is composed of:
    /// ```
    /// HTTP method
    /// path
    /// headers (\n separated)
    /// 
    /// signed headers names (;separated)
    /// payload hash
    /// ```
    func canonicalRequest(signedHeaders signedHeaders: String, payloadHash: String) -> String? {
        guard let method = self.HTTPMethod,
              let path = self.URL?.path,
              let headerFields = self.allHTTPHeaderFields else { return nil }
        
        let query = self.URL?.query ?? ""
        let fullPath = path.isEmpty ? "/" : path
        let headers = headerFields.map { (header, value) in
            return "\(header.lowercaseString):\(value)"
        }.sort().joinWithSeparator("\n")
        
        return "\(method)\n\(fullPath)\n\(query)\n\(headers)\n\n\(signedHeaders)\n\(payloadHash)"
    }
    
}
