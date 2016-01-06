import Foundation
import Accelerate

public protocol MKRegression {
    
    func univariate(X X: [Double], Y: [Double]) -> [Double]
    
}

public struct MKLinearRegression : MKRegression {
    
    ///
    /// Construct a la_object_t for a matrix of dimensions rows x columns
    /// - parameter The: array to use as the elements of the matrix
    /// - parameter The: number of rows to construct the matrix
    /// - parameter The: number of columns to construct the matrix
    /// - returns: The la_object_t instance to use in matrix operations
    ///
    func la_matrix_from_double_array(var array: [Double], rows: Int, columns: Int) -> la_object_t {
        let columns = la_count_t(columns)
        let rows = la_count_t(rows)
        
        let stride = columns
        var matrix: la_object_t!
        matrix = la_matrix_from_double_buffer(&array, rows, columns, stride, 0, 0)
        
        return matrix
    }
    
    ///
    /// Construct a la_object_t for a column matrix of size array.count x 1
    /// - parameter The: array to use as the elements of the column matrix
    /// - returns: The la_object_t instance to use in matrix operations
    ///
    func la_vector_column_from_double_array(array: [Double]) -> la_object_t {
        return la_matrix_from_double_array(array, rows: array.count, columns: 1)
    }
    
    ///
    /// Construct a la_object_t for a row matrix of size 1 x array.count
    /// - parameter The: array to use as the elements of the column matrix
    /// - returns: The la_object_t instance to use in matrix operations
    ///
    func la_vector_row_from_double_array(array: [Double]) -> la_object_t {
        return la_matrix_from_double_array(array, rows: 1, columns: array.count)
    }
    
    public func univariate(X X: [Double], Y: [Double]) -> [Double] {
        let m = X.count
        let alpha: Double = 0.01
        let numIterations: Int = 1500
        
        var xValues = [Double](count: m * 2, repeatedValue: 1.0)
        for i in 0.stride(to: X.count * 2, by: 2) {
            xValues[i] = X[i / 2]
        }
        
        let x = la_matrix_from_double_array(xValues, rows: m, columns: 2)
        let y = la_vector_column_from_double_array(Y)
        
        // 𝜃 = inverse(X' * X) * X' * y
        // Equivalent to (X' * X) * 𝜃 = X' * y hence can use la_solve
        //let newTheta = la_solve(la_transpose(x) * x, la_transpose(x) * y)
        
        //return newTheta.toArray()
        
        let thetaArray = [Double](count: Int(2), repeatedValue: 0.0)
        var theta = la_vector_row_from_double_array(thetaArray)
        
        let alphaOverM = alpha / Double(m)
        
        for _ in 0..<numIterations {
            // h(x) = transpose(theta) * x
            let prediction = la_matrix_product(x, theta)
            let errors = la_difference(prediction, y)
            let sum = la_matrix_product(la_transpose(errors), x)
            let partial = la_elementwise_product(la_transpose(sum), la_splat_from_double(alphaOverM, 0))
            
            // Simultaneous theta update:
            // theta_j = theta_j - alpha / m * sum_{i=1}^m (h_theta(x^(i)) - y^(i)) * x_j^(i)
            theta = la_difference(theta, partial)
        }
        
        var result = [Double](count: Int(la_matrix_rows(theta) * la_matrix_cols(theta)), repeatedValue: 0.0)
        la_matrix_to_double_buffer(&result, la_count_t(la_matrix_cols(theta)), theta)
        return result
    }
    
}
