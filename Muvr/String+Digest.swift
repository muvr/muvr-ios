import Foundation

extension String {
    
    func digest(algo: MRDigestAlgorithm) -> MRHmacDigest {
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)!
        let strLen = self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        return algo.digest(str, dataLength: strLen)
    }
    
    func digest(algo: MRDigestAlgorithm, key: MRHmacDigest) -> MRHmacDigest {
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)!
        let strLen = self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        return algo.digest(str, dataLength: strLen, key: key)
    }
    
    func digest(algo: MRDigestAlgorithm, key: String) -> MRHmacDigest {
        let keyStr = key.cStringUsingEncoding(NSUTF8StringEncoding)!
        return digest(algo, key: Array(keyStr[0..<keyStr.count-1]))
    }
    
    init(digest: MRHmacDigest) {
        let hash = NSMutableString()
        for i in digest {
            hash.appendFormat("%02x", UInt8(bitPattern: i))
        }
        self.init(format: hash as String)
    }
    
    init(strToHash: String, algo: MRDigestAlgorithm) {
        self.init(digest: strToHash.digest(algo))
    }
    
    init(strToSign: String, algo: MRDigestAlgorithm, key: MRHmacDigest) {
        self.init(digest: strToSign.digest(algo, key: key))
    }
    
    init(strToSign: String, algo: MRDigestAlgorithm, key: String) {
        self.init(digest: strToSign.digest(algo, key: key))
    }
    
}
