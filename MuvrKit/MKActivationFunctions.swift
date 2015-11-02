import Foundation
import Accelerate


public protocol MKActivationFunction {
    func applyOn(inout input: [Float], offset: Int, length: Int) -> ()
}

///
/// Logistic function: http://en.wikipedia.org/wiki/Logistic_function
///
public class SigmoidActivation: MKActivationFunction {
    public func applyOn(inout input: [Float], offset: Int, length: Int) {
        var one: Float = 1.0
        var minusOne: Float = -1.0
        let inputPointer: UnsafeMutablePointer<Float> = UnsafeMutablePointer(input).advancedBy(offset)
        
        vDSP_vneg(inputPointer, vDSP_Stride(1), inputPointer, vDSP_Stride(1), vDSP_Length(length))
        
        vvexpf(inputPointer, inputPointer, [Int32(length)])
        
        vDSP_vsadd(inputPointer, vDSP_Stride(1), &one, inputPointer, vDSP_Stride(1), vDSP_Length(length))
        
        vvpowsf(inputPointer, &minusOne, inputPointer, [Int32(length)])
    }
}
///
/// Use the tangens as an activation
///
public class TangentActivation: MKActivationFunction {
    public func applyOn(inout input: [Float], offset: Int, length: Int) {
        let inputPointer: UnsafeMutablePointer<Float> = UnsafeMutablePointer(input).advancedBy(offset)

        vvtanhf(inputPointer, inputPointer, [Int32(length)])
    }
}

///
/// Rectified Linear Unit, it computes point-wise y=max(0,x)
///
public class ReLUActivation: MKActivationFunction  {
    public func applyOn(inout input: [Float], offset: Int, length: Int) {
        var threshold: Float = 0.0

        vDSP_vthres(&input + offset, vDSP_Stride(1), &threshold, &input + offset, vDSP_Stride(1), vDSP_Length(length))
    }
}

///
/// Let's just not do anything with the outputs
///
public class IdentityActivation: MKActivationFunction  {
    public func applyOn(inout input: [Float], offset: Int, length: Int) {
    }
}