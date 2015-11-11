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
    static func parse(text text: String) -> MKActivationFunction? {
        switch text {
        case "id": return .Identity
        case "relu": return .ReLU
        case "logistic": return .Sigmoid
        case "sigmoid": return .Sigmoid
        case "tanh": return .Tanh
        default: return nil
        }
    }
    
}

///
/// Adds basic text parsing
///
public extension MKLayerConfiguration {
    
    /// Parse error
    public enum ParseError : ErrorType {
        /// Invalid size
        case InvalidSize(text: String)
        /// Invalid AF
        case InvalidActivationFunction(text: String)
    }

    ///
    /// Parses the given text and returns an array of ``MKLayerConfiguration``, which
    /// can be directly used for the rest of the classification structures
    /// - parameter text: the text to be parsed
    /// - returns: the parsed layer configuration
    ///
    public static func parse(text text: String) throws -> [MKLayerConfiguration] {
        let elements = text.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return try (0..<elements.count / 2).map { index in
            let sizeText = elements[index * 2]
            let activationFunctionText = elements[index * 2 + 1]
            guard let size = Int(sizeText) else { throw ParseError.InvalidSize(text: sizeText) }
            guard let activationFunction = MKActivationFunction.parse(text: activationFunctionText) else { throw ParseError.InvalidActivationFunction(text: activationFunctionText) }

            return MKLayerConfiguration(size: size, activationFunction: activationFunction)
        }

    }
    
}
