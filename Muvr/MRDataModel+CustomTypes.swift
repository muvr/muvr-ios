import Foundation
import SQLite

/// Custom NSUUID type
extension NSUUID : Value {
    public class var declaredDatatype: String {
        return String.declaredDatatype
    }
    public class func fromDatatypeValue(value: String) -> Self {
        return self(UUIDString: value)!
    }
    public var datatypeValue: String {
        return UUIDString
    }
}

/// Custom NSDate type
extension NSDate : Value {
    public class var declaredDatatype: String {
        return Int.declaredDatatype
    }
    public class func fromDatatypeValue(intValue: Int) -> Self {
        return self(timeIntervalSince1970: NSTimeInterval(intValue))
    }
    public var datatypeValue: Int {
        return Int(timeIntervalSince1970)
    }
}

extension JSON : Value {
    public static var declaredDatatype: String {
        return Blob.declaredDatatype
    }
    public static func fromDatatypeValue(blobValue: Blob) -> JSON {
        let dataValue = NSData(bytes: blobValue.bytes, length: blobValue.length)
        let object: AnyObject? = NSJSONSerialization.JSONObjectWithData(dataValue, options: NSJSONReadingOptions.AllowFragments, error: nil)
        if let o: AnyObject = object {
            return JSON(o)
        }
        return JSON.nullJSON
    }
    public var datatypeValue: Blob {
        let os = NSOutputStream.outputStreamToMemory()
        NSJSONSerialization.writeJSONObject(self.object, toStream: os, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
        let data: NSData = os.propertyForKey(NSStreamDataWrittenToMemoryStreamKey) as! NSData
        return Blob(bytes: data.bytes, length: data.length)
    }
    
}