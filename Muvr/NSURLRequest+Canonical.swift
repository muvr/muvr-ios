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
        
        /// fix the query string (alphabetical sort + / escaping)
        func fixQueryString(queryStr: String) -> String {
            // query string parameters need to be sorted alphabetically
            let params = queryStr.characters.split { return $0 == "&" }.map { return String($0) }.sort()
            // ``/`` character is not escaped automatically so replace it with ``%2f``
            return params.joinWithSeparator("&").stringByReplacingOccurrencesOfString("/", withString: "%2F")
        }
    
        let query = fixQueryString(self.URL?.query ?? "")
        let fullPath = path.isEmpty ? "/" : path
        let headers = headerFields.map { (header, value) in
            return "\(header.lowercaseString):\(value)"
        }.sort().joinWithSeparator("\n")
        
        return "\(method)\n\(fullPath)\n\(query)\n\(headers)\n\n\(signedHeaders)\n\(payloadHash)"
    }
    
}
