import Foundation
import Accelerate

public enum MKRepetitionEstimatorError : ErrorType {
    
    case MissingAccelerometerType
    
}

public struct MKRepetitionEstimator {
    public typealias Estimate = (UInt8, Double)
    
    
//    private func autocorrelation(data: [Float], dimension: Int) -> [Float] {
//        let filterLength = data.count
//        let resultLength = data.count
//        var correlation = [Float](count: resultLength, repeatedValue: 0)
//        var signal = data + [Float](count: filterLength + 1, repeatedValue: 0)
//        
//        (0..<dimension).forEach { d in
//            let dataPtr = UnsafePointer<Float>(data) + d
//            let correlationPtr: UnsafeMutablePointer<Float> = UnsafeMutablePointer<Float>(from: &correlation)
//            
//            vDSP_conv(&signal + d, vDSP_Stride(dimension), dataPtr, vDSP_Stride(dimension), correlationPtr.advancedBy(d), vDSP_Stride(dimension), vDSP_Length(resultLength), vDSP_Length(filterLength))
//        }
//    }
// 
//    
//    private func numberOfRepetitions(data: [Float], dimension: Int) -> Estimate {
//        
//    }
//

    public func estimate(data data: MKSensorData) throws -> Estimate {
        let (d, v) = data.samples(along: [.Accelerometer(location: .LeftWrist), .Accelerometer(location: .RightWrist)])
        if d == 0 { throw MKRepetitionEstimatorError.MissingAccelerometerType }

        fatalError("Not yet implemented")
    }
    
}
