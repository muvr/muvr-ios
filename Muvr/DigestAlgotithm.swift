import Foundation

typealias HmacDigest = [Int8]

enum DigestAlgorithm {
    case MD5, SHA256
    
    var hmacAlgorithm: CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:      result = kCCHmacAlgMD5
        case .SHA256:   result = kCCHmacAlgSHA256
        }
        return CCHmacAlgorithm(result)
    }
    
    var digestLength: Int {
        var result: Int32 = 0
        switch self {
        case .MD5:      result = CC_MD5_DIGEST_LENGTH
        case .SHA256:   result = CC_SHA256_DIGEST_LENGTH
        }
        return Int(result)
    }
    
    func digest(data: UnsafePointer<Void>, dataLength: Int) -> HmacDigest {
        let dataLen = UInt32(dataLength)
        let buffer = UnsafeMutablePointer<UInt8>.alloc(digestLength)
        
        switch self {
        case .MD5:      CC_MD5(data, UInt32(dataLen), buffer)
        case .SHA256:   CC_SHA256(data, UInt32(dataLen), buffer)
        }
        
        let hash = toBytes(buffer)
        buffer.destroy()
        return hash
    }
    
    func digest(data: UnsafePointer<Void>, dataLength: Int, key: HmacDigest) -> HmacDigest {
        let buffer = UnsafeMutablePointer<UInt8>.alloc(digestLength)
        CCHmac(hmacAlgorithm, key, key.count, data, dataLength, buffer)
        let hash = toBytes(buffer)
        buffer.destroy()
        return hash
    }
    
    private func toBytes(buffer: UnsafeMutablePointer<UInt8>) -> HmacDigest {
        let digestLen = digestLength
        var hash = [Int8](count: digestLen, repeatedValue: 0)
        for i in 0..<digestLen {
            hash[i] = Int8(bitPattern: buffer[i])
        }
        return hash
    }
}
