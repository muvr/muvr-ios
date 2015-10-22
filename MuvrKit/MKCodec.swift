import Foundation

enum MKCodecError : ErrorType {
    case NotEnoughInput
    case BadHeader
    case BadOffset
    
    case CompressionFailed
    case DecompressionFailed
}
