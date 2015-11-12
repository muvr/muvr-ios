import Foundation
import Accelerate

///
/// The definition of the activation function
///
public enum MKActivationFunction {
    /// f(x) = x
    case Identity
    /// f(x) = 1/(1 + e^x)
    case Sigmoid
    /// f(x) = tanh(x)
    case Tanh
    /// f(x) = max(0, x)
    case ReLU
}

///
/// Implements the ``MKActivationFunctionApplication`` for ``MKActivationFunction``
///
extension MKActivationFunction {

    ///
    /// Perform the inplace operation on ``input``, with non-negative ``offset`` and ``length``.
    /// - parameter input: the vector on which to apply the function
    /// - parameter offset: the offset in the vector
    /// - parameter length: the number of elements to process
    ///
    func applyOn(inout input: [Float], offset: Int, length: Int) {
        var one: Float = 1.0
        var minusOne: Float = -1.0
        var threshold: Float = 0.0
        let inputPointer: UnsafeMutablePointer<Float> = UnsafeMutablePointer(input).advancedBy(offset)

        switch self {
        case .Identity:
            /* noop */
            return
        case .Sigmoid:
            vDSP_vneg(inputPointer, vDSP_Stride(1), inputPointer, vDSP_Stride(1), vDSP_Length(length))
            vvexpf(inputPointer, inputPointer, [Int32(length)])
            vDSP_vsadd(inputPointer, vDSP_Stride(1), &one, inputPointer, vDSP_Stride(1), vDSP_Length(length))
            vvpowsf(inputPointer, &minusOne, inputPointer, [Int32(length)])
        case .ReLU:
            vDSP_vthres(&input + offset, vDSP_Stride(1), &threshold, &input + offset, vDSP_Stride(1), vDSP_Length(length))
        case .Tanh:
            vvtanhf(inputPointer, inputPointer, [Int32(length)])
        }
    }
    
}
