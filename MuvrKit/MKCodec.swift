import Foundation

enum MKCodecError : ErrorProtocol {
    case notEnoughInput
    case badHeader
    
    case compressionFailed
    case decompressionFailed
    
    case notSupported
}
