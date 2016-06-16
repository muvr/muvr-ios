import Foundation
import Accelerate

///
/// Polynomial fitting errors
///
enum MKPolynomialFitError : ErrorProtocol {
    /// The requested order ``k`` is greater than the ``maximum`` order
    case badPolynomialOrder(k: Int, maximum: Int)
    /// The x and y inputs have mismatched number of elements
    case inputCountsMismatched
    /// The x or y inputs are empty
    case inputEmpty
    /// The fitting failed
    case computationFailed
}

///
/// Implements polynomial fitting
///
struct MKPolynomialFitter {
    
    ///
    /// Fits the independent values ``x`` to dependent values ``y`` to a polynomial
    /// of ``degree``. The result is the array of coefficients 0..<degree. The
    /// coefficients _c_ represent the function
    /// _c_<sub>0</sub>x<sup>0</sup> + _c_<sub>1</sub>x<sup>1</sup> + ... + _c_<sub>n</sub>x<sup>n</sup>
    ///
    /// - parameter x: the array of independent values
    /// - parameter y: the array of dependent values _y_ = f(_x_)
    /// - parameter degree: the polynomial degree > 0
    /// - returns: the coefficients
    ///
    static func fit(x: [Float], y: [Float], degree: Int) throws -> [Float] {
        if x.count != y.count {
            throw MKPolynomialFitError.inputCountsMismatched
        }
        if x.isEmpty || y.isEmpty {
            throw MKPolynomialFitError.inputEmpty
        }
        
        // here on in, x and y are non-empty arrays
        let n = x.count
        let k = Int(degree - 1)
        if k > n - 1 {
            throw MKPolynomialFitError.badPolynomialOrder(k: k, maximum: n)
        }
        
        // trivial case
        if n == 1 { return [y.first!] }
        
        //initialize the M array
        //  [ Σ(i=1->N) xi^0,   Σ(i=1->N) xi^1,     Σ(i=1->N) xi^2, ...     Σ(i=1->N) xi^k ],
        //  [ Σ(i=1->N) xi^1,   Σ(i=1->N) xi^2,     Σ(i=1->N) xi^3, ...     Σ(i=1->N) xi^k+1 ],
        //  [ Σ(i=1->N) xi^2,   Σ(i=1->N) xi^3,     Σ(i=1->N) xi^4, ...     Σ(i=1->N) xi^k+2 ],
        //  [ ...,              ...,                ...            , ...     ... ],
        //  [ Σ(i=1->N) xi^k,   Σ(i=1->N) xi^k+1,   Σ(i=1->N) xi^k+2, ...   Σ(i=1->N) xi^2k ]
        var MData = [Float](repeating: 0, count: Int(degree * degree))
        for row in 0..<degree {
            for col in 0..<degree {
                let isFinalRow = row == degree - 1
                let isFinalCol = col == degree - 1
                
                var power: Int = 0
                if (!isFinalRow && !isFinalCol) {
                    //Σ(i=1->N) xi^(row + column) case
                    power = row + col
                } else if (isFinalRow && !isFinalCol) {
                    //Σ(i=1->N) xi^(k + column) case
                    power = k + col
                } else if (!isFinalRow && isFinalCol) {
                    //Σ(i=1->N) xi^(k + row) case
                    power = k + row
                } else {
                    //Σ(i=1->N) xi^(2k) case
                    power = 2 * k
                }
                
                let sum: Float = x.reduce(0) { r, x in r + powf(x, Float(power)) }
                let index = row * degree + col
                MData[index] = sum
            }
        }
        
        let M = la_matrix_from_float_buffer(MData, la_count_t(degree), la_count_t(degree), la_count_t(degree),
            la_hint_t(LA_FEATURE_SYMMETRIC), la_attribute_t(LA_DEFAULT_ATTRIBUTES))
        
        var bData = [Float](repeating: 0, count: degree)
        //  Σ(i=1->N) yi * xi^0,
        //  Σ(i=1->N) yi * xi^1,
        //  Σ(i=1->N) yi * xi^2,
        //  ...
        //  Σ(i=1->N) yi * xi^k,
        for j in 0..<degree {
            var sum: Float = 0
            for n in 0..<n {
                sum += y[n] * powf(x[n], Float(j))
            }
            bData[j] = sum
        }
        let b = la_matrix_from_float_buffer(bData, la_count_t(1), la_count_t(bData.count), la_count_t(bData.count), 0, 0)

        let a = la_solve(M, b)
        var aData = [Float](repeating: 0, count: degree)
        if la_vector_to_float_buffer(&aData, 1, a) != la_status_t(LA_SUCCESS) {
            throw MKPolynomialFitError.computationFailed
        }
        
        return aData
    }
    
}
