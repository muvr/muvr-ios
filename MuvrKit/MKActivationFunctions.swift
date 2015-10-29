import Foundation
import Accelerate

///
/// Logistic function: http://en.wikipedia.org/wiki/Logistic_function
///
public func sigmoidActivation(inout input: [Float], offset: Int, length: Int) {
    var one: Float = 1.0
    var mone: Float = -1.0
    
    input.withUnsafeBufferPointer{ sourcePointer  in
        let source = sourcePointer.baseAddress.advancedBy(offset)
        vDSP_vneg(source, vDSP_Stride(1), &input[offset], vDSP_Stride(1), vDSP_Length(length))
    }
    input.withUnsafeBufferPointer{ sourcePointer  in
        let source = sourcePointer.baseAddress.advancedBy(offset)
        vvexpf(&input[offset], source, [Int32(length)])
    }
    input.withUnsafeBufferPointer{ sourcePointer  in
        let source = sourcePointer.baseAddress.advancedBy(offset)
        vDSP_vsadd(source, vDSP_Stride(1), &one, &input[offset], vDSP_Stride(1), vDSP_Length(length))
    }
    input.withUnsafeBufferPointer{ sourcePointer  in
        let source = sourcePointer.baseAddress.advancedBy(offset)
        vvpowsf(&input[offset], &mone, source, [Int32(length)])
    }
}

///
/// Use the tangens as an activation
///
public func tangentActivation(inout input: [Float], offset: Int, length: Int) {
    input.withUnsafeBufferPointer{ sourcePointer  in
        let source = sourcePointer.baseAddress.advancedBy(offset)
        vvtanhf(&input[offset], source, [Int32(length)])
    }
}

///
/// Rectified Linear Unit, it computes point-wise y=max(0,x)
///
public func reLUActivation(inout input: [Float], offset: Int, length: Int) {
    let threshold: Float = 0.0
    input.withUnsafeBufferPointer{ sourcePointer  in
        let source = sourcePointer.baseAddress.advancedBy(offset)
        vDSP_vthres(source, vDSP_Stride(1), [threshold], &input[offset], vDSP_Stride(1), vDSP_Length(length))
    }
}

///
/// Let's just not do anything with the outputs
///
public func identityActivation(inout input: [Float], offset: Int, length: Int) {
    
}
