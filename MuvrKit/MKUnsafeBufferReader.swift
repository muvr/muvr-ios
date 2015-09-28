import Foundation

class MKUnsafeBufferReader {
    private let totalLength: Int
    private var offset: Int
    private let bytes: UnsafePointer<UInt8>
    
    init(bytes: UnsafePointer<UInt8>, totalLength: Int) {
        self.bytes = bytes
        self.totalLength = totalLength
        self.offset = 0
    }
    
    init(data: NSData) {
        self.bytes = UnsafePointer<UInt8>(data.bytes)
        self.totalLength = data.length
        self.offset = 0
    }
    
    func expect(value: UInt8) throws {
        if try next() != value {
            throw MKCodecError.UnexpectedValue
        }
    }
    
    func next<A>() throws -> A {
        return try nexts(1)[0]
    }
    
    func nexts<A>(count: Int) throws -> UnsafePointer<A> {
        let countBytes: Int = sizeof(A) * count
        if offset + countBytes - 1 < totalLength {
            let ptr = UnsafePointer<A>(bytes.advancedBy(offset))
            offset += countBytes
            return ptr
        }
        return nil
    }
        
    /// The readable length
    var length: Int {
        return totalLength - offset
    }
}
