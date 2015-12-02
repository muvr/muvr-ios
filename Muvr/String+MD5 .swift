import Foundation

extension String {

    func md5() -> String {
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
        let size = UInt32(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestSize = Int(CC_MD5_DIGEST_LENGTH)
        let md5 = UnsafeMutablePointer<UInt8>.alloc(digestSize)
        CC_MD5(str!, size, md5)
        let hash = NSMutableString()
        for i in 0..<digestSize {
            hash.appendFormat("%02x", md5[i])
        }
        md5.destroy()
        return String(format: hash as String)
    }
    
}