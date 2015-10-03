import Foundation
import Accelerate

public enum MKRepetitionEstimatorError : ErrorType {
    
    case MissingAccelerometerType
    
}

public struct MKRepetitionEstimator {
    public typealias Estimate = (UInt8, Double)
    
    private func ptrAdvancedBy(arr: UnsafeMutablePointer<Float>, n: Int) -> UnsafeMutablePointer<Float> {
        return arr.advancedBy(n)
    }
    

    public func estimate(data data: MKSensorData) throws -> Estimate {
        let (sampleDimension, sampleData) = data.samples(along: [.Accelerometer(location: .LeftWrist), .Accelerometer(location: .RightWrist)])
        if sampleDimension == 0 { throw MKRepetitionEstimatorError.MissingAccelerometerType }

        // MARK: Setup basic variables
        let sampleDataLength = sampleData.count / sampleDimension
        
        var correlation = [Float](count: sampleData.count, repeatedValue: 0)
        var signal = sampleData + [Float](count: sampleData.count + 1, repeatedValue: 0)
        
        let peaks = (0..<sampleDimension).map { (d: Int) -> [Int] in
            var peaks: [Int] = []
            let nDowns = 1
            let nUps = 1

            // MARK: First, compute autocorrelation across all dimensions of our data
            let dataPtr = UnsafePointer<Float>(sampleData) + d
            vDSP_conv(&signal + d, vDSP_Stride(sampleDimension), dataPtr, vDSP_Stride(sampleDimension), ptrAdvancedBy(&correlation, n: d), vDSP_Stride(sampleDimension), vDSP_Length(sampleDataLength), vDSP_Length(sampleDataLength))

            var max: Float = 2.0 / correlation[0]
            var shift: Float = -1
            vDSP_vsmsa(&correlation, vDSP_Stride(d), &max, &shift, &correlation, vDSP_Stride(d), vDSP_Length(correlation.count))

            // MARK: Next, find peaks in each dimension
            for var i = nDowns; i < sampleDataLength - nUps; ++i {
                let idx = i + (d * sampleDataLength)
                var isPeak = true
                for var j = -nDowns; j < nUps && isPeak; ++j {
                    if j < 0 { isPeak = isPeak && sampleData[i + j] <  sampleData[i + j + 1] }
                    else     { isPeak = isPeak && sampleData[i + j] >= sampleData[i + j + 1] }
                }
                if isPeak { peaks.append(idx) }
            }

            return peaks
        }
        
        print(peaks)

        fatalError("Not yet implemented")
    }
    
}
