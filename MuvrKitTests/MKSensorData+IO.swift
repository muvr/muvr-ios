import Foundation
@testable import MuvrKit

enum MKSensorDataIOError : ErrorType {
    case ResourceMissing(resourceName: String)
}

extension MKSensorData {

    ///
    /// Loads the ``MKSensorData`` from the CSV file that must contain the raw data for it
    ///
    /// - parameter types: the types that represent the values in the CSV file
    /// - parameter samplesPerSecond: the sampling rate
    /// - parameter resourceName: the resource to load, relative to ``MuvrKitTests.self``
    /// - returns: the loaded ``MKSensorData``
    /// - throws: one of ``MKSensorDataIOError``
    ///
    static func sensorData(types types: [MKSensorDataType], samplesPerSecond: UInt, loading resourceName: String) throws -> MKSensorData {
        if let fileName = NSBundle(forClass: MuvrKitTests.self).pathForResource(resourceName, ofType: "csv") {
            let contents = try NSString(contentsOfFile: fileName, encoding: NSASCIIStringEncoding)
            
            let nums = contents.componentsSeparatedByString(",").map { x in return Float(x.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))! }
            return try MKSensorData(types: types, start: 0, samplesPerSecond: samplesPerSecond, samples: nums)
        } else {
            throw MKSensorDataIOError.ResourceMissing(resourceName: resourceName)
        }
    }
    
    ///
    /// The generator value
    ///
    enum Value {
        /// A specified constant
        /// - parameter value: the constant value
        case Constant(value: Float)
        
        /// A sine wave with the given period, and 1.0 amplitude
        /// - parameter period: the period in samples
        case Sin1(period: Int)
    }
    
    ///
    /// Generated ``MKSensorData`` of the specified ``types``, ``samplesPerSecond``, containing the given ``numRows``, each row with 
    /// samples generated using the "recipe" specified by ``value``.
    /// 
    /// - parameter types: the types that should be included
    /// - parameter samplesPerSecond: the sampling rate
    /// - parameter numRows: the number of rows to generate
    /// - parameter value: the value to be set to every row
    /// - returns: the generated ``MKSensorData``
    ///
    static func sensorData(types types: [MKSensorDataType], samplesPerSecond: UInt, generating numRows: Int, withValue value: Value) -> MKSensorData {
        func generateValue(value: Value, index: Int) -> Float {
            switch value {
            case .Constant(let x): return x
            case .Sin1(let p): return sinf(Float(index) / Float(p))
            }
        }
        
        let dimension = types.reduce(0) { r, e in return r + e.dimension }
        let samples = (0..<dimension * numRows).map { idx in return generateValue(value, index: idx / dimension) }
        return try! MKSensorData(types: types, start: 0, samplesPerSecond: samplesPerSecond, samples: samples)
    }
    
}
