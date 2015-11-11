import Foundation

extension MKActivationFunction {
    
    static func parse(text: String) -> MKActivationFunction? {
        switch text {
        case "id": return .Identity
        case "relu": return .ReLU
        case "logistic": return .Sigmoid
        case "tanh": return .Tanh
        default: return nil
        }
    }
    
}

public extension MKLayerConfiguration {
    
    public static func parse(text: String) -> [MKLayerConfiguration] {
        let elements = text.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return (0..<elements.count / 2).flatMap { index in
            let size = elements[index * 2]
            let activationFunction = elements[index * 2 + 1]
            if let size = Int(size), activationFunction = MKActivationFunction.parse(activationFunction) {
                return MKLayerConfiguration(size: size, activationFunction: activationFunction)
            }
            return nil
        }

    }
    
}
