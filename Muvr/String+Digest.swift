import Foundation

extension String {
    
    /// Computes the hash of this string using the specified algorithm
    func digest(algo: DigestAlgorithm) -> HmacDigest {
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)!
        let strLen = self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        return algo.digest(str, dataLength: strLen)
    }
    
    /// Computes the signature of this string using the specified algorithm and key
    func digest(algo: DigestAlgorithm, key: HmacDigest) -> HmacDigest {
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)!
        let strLen = self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        return algo.digest(str, dataLength: strLen, key: key)
    }
    
    /// Computes the signature of this string using the specified algorithm and key
    func digest(algo: DigestAlgorithm, key: String) -> HmacDigest {
        let keyStr = key.cStringUsingEncoding(NSUTF8StringEncoding)!
        return digest(algo, key: Array(keyStr[0..<keyStr.count-1]))
    }
    
    /// Builds a hex-string of the digest (byes) passed in
    init(digest: HmacDigest) {
        let hash = NSMutableString()
        for i in digest {
            hash.appendFormat("%02x", UInt8(bitPattern: i))
        }
        self.init(format: hash as String)
    }
    
    /// Builds a hex-string of the hash of this string using the specified algorithm
    init(strToHash: String, algo: DigestAlgorithm) {
        self.init(digest: strToHash.digest(algo))
    }
    
    /// Builds a hex-string of the signature of this string using the specified algorithm and key
    init(strToSign: String, algo: DigestAlgorithm, key: HmacDigest) {
        self.init(digest: strToSign.digest(algo, key: key))
    }
    
    /// Builds a hex-string of the signature of this string using the specified algorithm and key
    init(strToSign: String, algo: DigestAlgorithm, key: String) {
        self.init(digest: strToSign.digest(algo, key: key))
    }
    
}