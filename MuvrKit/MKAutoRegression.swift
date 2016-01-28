import Accelerate
import Foundation

enum MKAutoRegressionError : ErrorType {
    /// The autoregression failed
    case ComputationFailed
    /// The order is not valid (order needs to be positive)
    case InvalidOrder
    /// There is not enought samples in the sequence to compute all the coefficient
    case NotEnoughSamples
}

struct MKAutoRegression {

    /// Compute the autoregression coefficients for the given sequence x using the least squares method
    /// - parameter x : the input sequence
    /// - parameter order : the number of coefficients
    static func leastSquares(x: [Float], order: Int) throws -> [Float] {
        if order <= 0 {
            throw MKAutoRegressionError.InvalidOrder
        }
        let l = Float(x.count - order)
        if l < 2 { // requires at least order + 2 terms to get valid results
            throw MKAutoRegressionError.NotEnoughSamples
        }
        
        var bData = [Float](count: order, repeatedValue: 0)
        var MData = [Float](count: Int(order * order), repeatedValue: 0)
        
        // create a symetric matrix of covariance values for the past timeseries elements
        // and a vector with covariances between the past timeseries elements and the timeseries element to estimate.
        // start at "order"-th sample and repeat this for the length of the timeseries
        for i in (order-1)..<(x.count-1) {
            for j in 0..<order {
                bData[j] += x[i+1] * x[i-j]
                for k in j..<order {
                    MData[j * order + k] += x[i-j] * x[i-k]
                }
            }
        }
        
        //calculate the mean values for the matrix and the coefficients vector according to the length of the timeseries
        for i in 0..<order {
            bData[i] /= l
            for j in i..<order {
                let index = i * order + j
                MData[index] /= l
                MData[j * order + i] = MData[index] //use the symmetry of the matrix
            }
        }
        
        // solves a . M = b
        let M = la_matrix_from_float_buffer(MData, la_count_t(order), la_count_t(order), la_count_t(order),
            la_hint_t(LA_FEATURE_SYMMETRIC), la_attribute_t(LA_DEFAULT_ATTRIBUTES))
        
        let b = la_matrix_from_float_buffer(bData, la_count_t(1), la_count_t(order), la_count_t(order), 0, 0)
        
        let a = la_solve(M, b)
        
        var aData = [Float](count: order, repeatedValue: 0)
        if la_vector_to_float_buffer(&aData, 1, a) != la_status_t(LA_SUCCESS) {
            throw MKAutoRegressionError.ComputationFailed
        }
        
        return aData
    }
    
    /// Compute the autoregression coefficients for the given sequence x using the max entropy method
    /// - parameter x : the input sequence
    /// - parameter order : the number of coefficients
    static func maxEntropy(x: [Float], order: Int) throws -> [Float] {
        if order <= 0 {
            throw MKAutoRegressionError.InvalidOrder
        }
        
        let l = x.count
        var per = [Float](count: l+1, repeatedValue: 0)
        var pef = [Float](count: l+1, repeatedValue: 0)
        var h = [Float](count: order+1, repeatedValue: 0)
        var g = [Float](count: order+2, repeatedValue: 0)
        var coef = [Float](count: order, repeatedValue: 0)
        var ar = [Float](count: (order+1)*(order+1), repeatedValue: 0)
        var t1: Float = 0
        var t2: Float = 0
        
        for i in 0..<order {
            let n = i + 1
            var sn: Float = 0
            var sd: Float = 0
            var jj = l - n
            for j in 0..<(l-n) {
                t1 = x[j+n] + pef[j]
                t2 = x[j]   + per[j]
                sn -= 2 * t1 * t2
                sd += (t1 * t1) + (t2 * t2)
            }
            g[n] = sn / sd
            t1 = g[n]
            
            for j in 1..<n {
                h[j] = g[j] + t1 * g[n-j]
            }
            for j in 1..<n {
                g[j] = h[j]
            }
            if n != 1 { jj-- }
            
            for j in 0..<jj {
                per[j] += t1 * pef[j] + t1 * x[j+n]
                pef[j] = pef[j+1] + t1 * per [j+1] + t1 * x[j + 1]
            }
            
            for j in 0..<n {
                ar[n * (order+1) + j] = g[j+1]
            }
            
        }
        
        for i in 0..<order {
            coef[i] = -ar[order * (order + 1) + i]
        }
        
        return coef
    }
    
}
