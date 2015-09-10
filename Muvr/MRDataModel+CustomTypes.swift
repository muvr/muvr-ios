import Foundation
import SQLite

/// Custom NSUUID type
extension NSUUID : Value {
    public class var declaredDatatype: String {
        return String.declaredDatatype
    }
    public class func fromDatatypeValue(value: String) -> NSUUID {
        return self.init(UUIDString: value)!
    }
    public var datatypeValue: String {
        return UUIDString
    }
}

/// Custom NSDate type
//extension NSDate : Value {
//    public class var declaredDatatype: String {
//        return Int.declaredDatatype
//    }
//    public class func fromDatatypeValue(intValue: Int) -> NSDate {
//        return self.init(timeIntervalSince1970: NSTimeInterval(intValue))
//    }
//    public var datatypeValue: Int {
//        return Int(timeIntervalSince1970)
//    }
//}

//extension NSData : Value {
//    public class var declaredDatatype: String {
//        return Blob.declaredDatatype
//    }
//    public class func fromDatatypeValue(blobValue: Blob) -> NSData {
//        return self(bytes: blobValue.bytes, length: blobValue.length)
//    }
//    public var datatypeValue: Blob {
//        return Blob(bytes: bytes, length: length)
//    }
//}
//
extension JSON : Value {
    public static var declaredDatatype: String {
        return Blob.declaredDatatype
    }
    public static func fromDatatypeValue(blobValue: Blob) -> JSON {
        let dataValue = NSData(bytes: blobValue.bytes, length: blobValue.bytes.count)
        do {
            let object: AnyObject? = try NSJSONSerialization.JSONObjectWithData(dataValue, options: NSJSONReadingOptions.AllowFragments)
            if let o: AnyObject = object {
                return JSON(o)
            }
        } catch _ {
            
        }
        return JSON.nullJSON
    }
    public var datatypeValue: Blob {
        let os = NSOutputStream.outputStreamToMemory()
        os.open()
        NSJSONSerialization.writeJSONObject(self.object, toStream: os, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
        os.close()
        let data: NSData = os.propertyForKey(NSStreamDataWrittenToMemoryStreamKey) as! NSData
        return Blob(bytes: data.bytes, length: data.length)
    }
    
}