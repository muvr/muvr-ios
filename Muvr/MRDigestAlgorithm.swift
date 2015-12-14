import Foundation

typealias MRHmacDigest = [Int8]

enum MRDigestAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    var hmacAlgorithm: CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:      result = kCCHmacAlgMD5
        case .SHA1:     result = kCCHmacAlgSHA1
        case .SHA224:   result = kCCHmacAlgSHA224
        case .SHA256:   result = kCCHmacAlgSHA256
        case .SHA384:   result = kCCHmacAlgSHA384
        case .SHA512:   result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    var digestLength: Int {
        var result: Int32 = 0
        switch self {
        case .MD5:      result = CC_MD5_DIGEST_LENGTH
        case .SHA1:     result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:   result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:   result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:   result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:   result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
    
    func digest(data: UnsafePointer<Void>, dataLength: Int) -> MRHmacDigest {
        let dataLen = UInt32(dataLength)
        let buffer = UnsafeMutablePointer<UInt8>.alloc(digestLength)
        
        switch self {
        case .MD5:      CC_MD5(data, UInt32(dataLen), buffer)
        case .SHA1:     CC_SHA1(data, UInt32(dataLen), buffer)
        case .SHA224:   CC_SHA224(data, UInt32(dataLen), buffer)
        case .SHA256:   CC_SHA256(data, UInt32(dataLen), buffer)
        case .SHA384:   CC_SHA384(data, UInt32(dataLen), buffer)
        case .SHA512:   CC_SHA512(data, UInt32(dataLen), buffer)
        }
        
        let hash = toBytes(buffer)
        buffer.destroy()
        return hash
    }
    
    func digest(data: UnsafePointer<Void>, dataLength: Int, key: MRHmacDigest) -> MRHmacDigest {
        let buffer = UnsafeMutablePointer<UInt8>.alloc(digestLength)
        CCHmac(hmacAlgorithm, key, key.count, data, dataLength, buffer)
        let hash = toBytes(buffer)
        buffer.destroy()
        return hash
    }
    
    private func toBytes(buffer: UnsafeMutablePointer<UInt8>) -> MRHmacDigest {
        let digestLen = digestLength
        var hash = [Int8](count: digestLen, repeatedValue: 0)
        for i in 0..<digestLen {
            hash[i] = Int8(bitPattern: buffer[i])
        }
        return hash
    }
}