import Foundation

enum MKCodecError : ErrorType {
    case NotEnoughInput
    case BadHeader
    case UnexpectedValue
    
    case CompressionFailed
    case DecompressionFailed
}
