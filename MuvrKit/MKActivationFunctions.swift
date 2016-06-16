import Foundation
import Accelerate

///
/// The definition of the activation function
///
public enum MKActivationFunction {
    /// f(x) = x
    case identity
    /// f(x) = 1/(1 + e^-x)
    case sigmoid
    /// f(x) = tanh(x)
    case tanh
    /// f(x) = max(0, x)
    case relu
    /// f(x) = e^x_k / sum_i(e^x_i)
    case softmax
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
    func applyOn(_ input: inout [Float], offset: Int, length: Int) {
        var one: Float = 1.0
        var minusOne: Float = -1.0
        var threshold: Float = 0.0
        let inputPointer: UnsafeMutablePointer<Float> = UnsafeMutablePointer(input).advanced(by: offset)

        switch self {
        case .identity:
            /* noop */
            return
        case .sigmoid:
            vDSP_vneg(inputPointer, vDSP_Stride(1), inputPointer, vDSP_Stride(1), vDSP_Length(length))
            vvexpf(inputPointer, inputPointer, [Int32(length)])
            vDSP_vsadd(inputPointer, vDSP_Stride(1), &one, inputPointer, vDSP_Stride(1), vDSP_Length(length))
            vvpowsf(inputPointer, &minusOne, inputPointer, [Int32(length)])
        case .softmax:
            var max: Float = 0
            vDSP_maxv(inputPointer, vDSP_Stride(1), &max, vDSP_Length(length))
            max = -max
            vDSP_vsadd(inputPointer, vDSP_Stride(1), &max, inputPointer, vDSP_Stride(1), vDSP_Length(length))
            vvexpf(inputPointer, inputPointer, [Int32(length)])
            var sum: Float = 0
            vDSP_sve(inputPointer, vDSP_Stride(1), &sum, vDSP_Length(length))
            vDSP_vsdiv(inputPointer, vDSP_Stride(1), &sum, inputPointer, vDSP_Stride(1), vDSP_Length(length))
        case .relu:
            vDSP_vthres(inputPointer, vDSP_Stride(1), &threshold, inputPointer, vDSP_Stride(1), vDSP_Length(length))
        case .tanh:
            vvtanhf(inputPointer, inputPointer, [Int32(length)])
        }
    }
    
}
