import Accelerate
import Foundation

struct MKLinearRegression {

    
    ///
    /// Returns a matrix with terms up to ``degree`` degree 
    /// if input matrix ``x`` has dimension [m x n]
    /// it returns a matrix of dimension [k x n] where k = degree * m + 1
    /// E.g if m= 2 then x rows are of the form [x0 x1]
    ///     if degree = 2 then the result rows are of the form [1 x0 x1 x0^2 x1^2]
    /// [[1,2],
    ///  [3,4]]
    ///
    /// Example:  x=[1,2, 3,4] with m=2 and degree=2
    /// then result=[1,1,2,1,4, 1,3,4,9.16]
    ///
    internal static func format(x:[Float], m: Int, degree: Int) -> [Float] {
        let k = degree * m + 1
        let n = x.count / m
        assert(m > 0)
        assert(degree >= 0)
        assert(x.count == m * n)
        
        var x_: [Float] = [Float](count: k * n, repeatedValue: 0)
        for i in 0..<(n * k) {
            let col = i % k
            let row = i / k
            let d = ceil(Float(col) / Float(m))
            let j = row * m + (1 + col) % m
            if col == 0 { x_[i] = 1.0 }
            else { x_[i] = pow(x[j], d) }
        }
        return x_
    }
    
    ///
    /// Find the best coefficients θ to solve the equation:
    ///   θ0 + θ1.x1 + θ2.x2 + ... + θm.xm + θ(m+1).x1^2 + ... + θ(deg*m).xm^deg = y
    /// Θ has dimension (1 + m * degree)
    ///
    /// parameter x: [mxn] input matrix
    /// parameter y: [m] vector
    /// parameter m: the number of variables (columns) in x
    /// parameter degree: the degree used to solve the equation
    /// returns an array of length (1 + m * degree) containing the θ coefficients
    ///
    static func train(x: [Float], y: [Float], m: Int, degree: Int) -> [Float] {
        let n = x.count / m
        let k = degree * m + 1
        
        var dims = [Bool](count: m, repeatedValue: false)
        dims = x.enumerate().reduce(dims) { (var dims, e) in
            let (i, v) = e
            let col = i % m
            if v != x[col] {
                dims[col] = true
            }
            return dims
        }
        
        let m_ = dims.filter { $0 }.count
        let k_ = degree * m_ + 1
        let x_ = validInput(x, dims: dims, degree: degree) // remove constant columns from x
        
        if x_.isEmpty {
            var θ = [Float](count: k, repeatedValue: 0)
            θ[0] = y[0]
            return θ
        }
        
        let defaultAttr = la_attribute_t(LA_DEFAULT_ATTRIBUTES)
        let noHint = la_hint_t(LA_NO_HINT)
        
        let input = format(x_, m: m_, degree: degree) // add columns for all degrees
        
        let X = la_matrix_from_float_buffer(input, la_count_t(n), la_count_t(k_), la_count_t(k_), noHint, defaultAttr)
        let Y = la_matrix_from_float_buffer(y, la_count_t(n), la_count_t(1), la_count_t(1), noHint, defaultAttr)
        let X_ = la_transpose(X)
        
        /// Solves Θ in the equation (X'.X).Θ = (X'.Y)
        let Θ = la_solve(la_matrix_product(X_, X), la_matrix_product(X_, Y))
        
        let θ = fixCoefficients(Θ, dims: dims, degree: degree)
        
        if θ.isEmpty {
            // Couldn't solve, return a constant value
            var θ = [Float](count: k, repeatedValue: 0)
            θ[0] = y[0]
            return θ
        }
        
        return θ
    }
    
    ///
    /// Remove columns containing always the same value
    /// - parameter x: the original input matrix (size n x m)
    /// - parameter dims: array of size m where true indicate valid columns, invalid columns are removed from x
    /// - parameter degree: the degree used in the linear regression
    /// - return a matrix of size (n x m_) where m_ is the number of valid dimensions
    private static func validInput(x: [Float], dims: [Bool], degree: Int) -> [Float] {
        let m = dims.count
        let n = x.count / m
        
        let m_ = dims.filter { $0 }.count
        
        var x_ = [Float](count: m_ * n, repeatedValue: 0)
        var j = 0
        for i in 0..<(m * n) {
            let col = i % m
            if dims[col] { x_[j++] = x[i] }
        }
        return x_
    }
    
    ///
    /// Θ has size (1 x k_): contains only coefficients for valid columns
    /// but need to return an array of size k where invalid columns have 0 coefficients
    /// - parameter Θ: the coefficient matrix returned by la_solve
    /// - parameter dims: array of size m where true indicate valid columns
    /// - parameter degree: the degree used in the linear regression
    /// - return an array of length k (or empty if Θ is empty)
    ///
    private static func fixCoefficients(Θ: la_object_t, dims: [Bool], degree: Int) -> [Float] {
        guard la_matrix_cols(Θ) > 0 else { return [] }
        
        let m = dims.count
        let k = degree * m + 1
        
        let m_ = dims.filter { $0 }.count
        let k_ = degree * m_ + 1
        
        var θ_ = [Float](count: k_, repeatedValue: 0)
        la_vector_to_float_buffer(&θ_, 1, Θ)
        
        var θ = [Float](count: k, repeatedValue: 0)
        var j = 0
        for i in 0..<k {
            if i == 0 { θ[0] = θ_[j++] }
            else {
                let col = (i - 1) % m
                if dims[col] { θ[i] = θ_[j++] }
            }
        }
        
        return θ
    }
    
    ///
    /// estimate the y value given a sample x and the coefficients θ
    ///
    static func estimate(x: [Float], θ: [Float]) -> Float {
        let k = θ.count
        let m = x.count
        var y: Float = θ[0]
        for i in 1..<k {
            let c = (i-1) % m
            y += θ[i] * pow(x[c], ceil(Float(i) / Float(m)))
        }
        return y
    }
    
}