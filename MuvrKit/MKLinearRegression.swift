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
        let k = degree * m + 1
        let n = x.count / m
        let x_ = format(x, m: m, degree: degree)
        
        let X = la_matrix_from_float_buffer(x_, la_count_t(n), la_count_t(k), la_count_t(k), la_hint_t(LA_NO_HINT), la_attribute_t(LA_DEFAULT_ATTRIBUTES))
        let Y = la_matrix_from_float_buffer(y, la_count_t(n), la_count_t(1), la_count_t(1), la_hint_t(LA_NO_HINT), la_attribute_t(LA_DEFAULT_ATTRIBUTES))
    
        /// Solves Θ in the equation (X'.X).Θ = (X'.Y)
        let Θ = la_solve(la_matrix_product(la_transpose(X), X), la_matrix_product(la_transpose(X), Y))
        
        var θ = [Float](count: k, repeatedValue: 0)
        la_vector_to_float_buffer(&θ, 1, Θ)
        
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