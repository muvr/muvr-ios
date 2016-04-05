import Foundation
import Accelerate

public enum MKRepetitionEstimatorError : ErrorType {
    
    case MissingAccelerometerType
    
}

public struct MKRepetitionEstimator {
    public typealias Estimate = (Int, Double)
    
    ///
    /// Holds information about a periodic profile
    ///
    private struct PeriodicProfile {
        // Abosolute amount the signal changed in the period
        var totalSteps: Float {
            return upwardSteps + downwardSteps
        }
        // Upwards steps of the signal
        var upwardSteps: Float = 0
        // Downwards steps of the signal
        var downwardSteps: Float = 0

        ///
        /// Determines whether ``self`` is roughly equal to ``that``, given ``margin``
        ///
        /// - parameter that: the other PP to compare
        /// - parameter margin: the margin
        /// - returns: ``true`` if ``self`` ~= ``that`` given ``margin``
        ///
        func roughlyEquals(that: PeriodicProfile, margin: Float) -> Bool {
            func ire(a a: Float, b: Float, margin: Float) -> Bool {
                return a > (b - margin) && a < (b + margin)
            }
            
            return ire(a: self.totalSteps, b: that.totalSteps, margin: margin)
        }
    }
    
    public func estimate(data data: MKSensorData) throws -> Estimate {
        let (sampleDimension, sampleData) = data.samples(along: [.Accelerometer(location: .LeftWrist), .Accelerometer(location: .RightWrist)])
        if sampleDimension == 0 { throw MKRepetitionEstimatorError.MissingAccelerometerType }

        // MARK: Setup basic variables
        let sampleDataLength = sampleData.count / sampleDimension
        let preprocessor = MKInputPreparator()
        
        // MARK: First, compute autocorrelation across all dimensions of our data, summing & finding peaks along the way

        //
        // The ``sampleData`` is a continuous array of ``Float``s, containing ``sampleDimension`` dimensions. For example, for
        // a single accelerometer data, we have ``sampleDimension == 3``, and the values in the ``sampleData`` are 
        // ``[x0, y0, z0; x1, y1, z1; ... xn, yn, zn]``. 
        //
        var convolutedSignal = [Float](count: sampleDataLength, repeatedValue: 0.0)
        
        var correlation = [Float](count: sampleDataLength, repeatedValue: 0.0)
        
        // Convolute the different dimensions to a single one by smoothing and adding them together
        (0..<sampleDimension).forEach { (d: Int) in
            var smoothedSignal = preprocessor.highpassfilter(sampleData, rate: 1/50, freq: 1/5, offset: d, stride: sampleDimension)
            vDSP_vadd(&convolutedSignal, vDSP_Stride(1),
                      &smoothedSignal, vDSP_Stride(1),
                      &convolutedSignal, vDSP_Stride(1),
                      vDSP_Length(sampleDataLength))
        }
        
        var paddedSignal = convolutedSignal + [Float](count: sampleDataLength - 1, repeatedValue: 0.0)
        
        // Compute autocorrelation of the padded signal with itself
        vDSP_conv(&paddedSignal, vDSP_Stride(1),
            &convolutedSignal, vDSP_Stride(1),
            &correlation, vDSP_Stride(1),
            vDSP_Length(sampleDataLength),
            vDSP_Length(sampleDataLength))
        
        var max: Float = 2.0 / correlation[0]
        var shift: Float = -1
        
        // Normalize the correlation values between 1 and -1
        vDSP_vsmsa(&correlation, vDSP_Stride(1),
             &max, &shift,
             &correlation, vDSP_Stride(1),
             vDSP_Length(sampleDataLength))
        
        // correlation = highpassfilter(correlation, rate: 1/50, freq: (1.0/Float(correlation.count)))
        
        var peaks: [Int] = []
        let nDowns = 1
        let nUps = 1

        // For debug purpouses to plot the data in R
        // NSLog(convolutedSignal.map{"\($0)"}.joinWithSeparator(","))
        // NSLog(correlation.map{"\($0)"}.joinWithSeparator(","))
        
        for i in nDowns ..< sampleDataLength - nUps {
            var isPeak = true
            for var j = -nDowns; j < nUps && isPeak; j += 1 {
                let idx  = i + j
                let idx1 = i + j + 1
                if j < 0 { isPeak = isPeak && correlation[idx] <  correlation[idx1] }
                else     { isPeak = isPeak && correlation[idx] >= correlation[idx1] }
            }
            if isPeak { peaks.append(i) }
        }
        
        // MARK: Compute period profiles, they describe the abstract shape of the peak
        var previousPeakLocation = 0
        var previousHeight: Float = 0
        var currentHeight: Float = 0
        var profiles = (0..<peaks.count).map { (i: Int) -> PeriodicProfile in
            var profile = PeriodicProfile()
            for j in previousPeakLocation ..< peaks[i] - 1 {
                previousHeight = convolutedSignal[j]
                currentHeight = convolutedSignal[j + 1]
                let steps = previousHeight - currentHeight
                if steps > 0 {
                    profile.upwardSteps += steps
                } else {
                    profile.downwardSteps += steps
                }
            }
            previousPeakLocation = peaks[i]
            
            return profile
        }
        
        if profiles.count > 0 {
            // MARK: Compute the mean profile from the list of profiles
            profiles.sortInPlace { $0.totalSteps < $1.totalSteps }
            let meanProfile = profiles[profiles.count / 2]

            // MARK: Count the repetitions
            let minimumPeakDistance = 50
            let (count, _) = (0..<peaks.count).reduce((0, 0)) { x, i in
                let (count, previousPeakLocation) = x
                let msp = peaks[i]
                if msp - previousPeakLocation >= minimumPeakDistance && profiles[i].roughlyEquals(meanProfile, margin: 1) {
                    return (count + 1, msp)
                } else {
                    return (count, msp)
                }
            }
            
            return (count, 1)
        } else {
            return (0, 1)
        }
    }
    
}
