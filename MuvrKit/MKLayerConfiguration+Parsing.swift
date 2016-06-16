import Foundation

///
/// Adds the basic text parsing
///
extension MKActivationFunction {

    ///
    /// Parses the text that represents the activation function
    /// - parameter text: the name of the activation function
    /// - returns: a parsed ``MKActivationFunction`` if ``text`` is valid, ``nil`` otherwise
    ///
    static func parse(text: String) -> MKActivationFunction? {
        switch text {
        case "id": return .identity
        case "relu": return .relu
        case "logistic": return .sigmoid
        case "sigmoid": return .sigmoid
        case "softmax": return .softmax
        case "tanh": return .tanh
        default: return nil
        }
    }
    
}

///
/// Adds basic text parsing
///
public extension MKLayerConfiguration {
    
    /// Parse error
    public enum ParseError : ErrorProtocol {
        /// Invalid size
        case invalidSize(text: String)
        /// Invalid AF
        case invalidActivationFunction(text: String)
    }

    ///
    /// Parses the given text and returns an array of ``MKLayerConfiguration``, which
    /// can be directly used for the rest of the classification structures
    /// - parameter text: the text to be parsed
    /// - returns: the parsed layer configuration
    ///
    public static func parse(text: String) throws -> [MKLayerConfiguration] {
        let elements = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        return try (0..<elements.count / 2).map { index in
            let sizeText = elements[index * 2]
            let activationFunctionText = elements[index * 2 + 1]
            guard let size = Int(sizeText) else { throw ParseError.invalidSize(text: sizeText) }
            guard let activationFunction = MKActivationFunction.parse(text: activationFunctionText) else { throw ParseError.invalidActivationFunction(text: activationFunctionText) }

            return MKLayerConfiguration(size: size, activationFunction: activationFunction)
        }

    }
    
}
