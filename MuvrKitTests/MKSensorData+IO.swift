import Foundation
@testable import MuvrKit

enum MKSensorDataIOError : ErrorType {
    case ResourceMissing(resourceName: String)
}

extension MKSensorData {

    ///
    /// Loads the MKSensorData from the CSV file that must contain the raw data for it
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
    
    enum Value {
        case Constant(value: Float)
    }
    
    static func sensorData(types types: [MKSensorDataType], samplesPerSecond: UInt, generating numRows: Int, withValue value: Value) -> MKSensorData {
        func generateValue(value: Value)(index: Int) -> Float {
            switch value {
            case .Constant(let x): return x
            }
        }
        
        let dimension = types.reduce(0) { r, e in return r + e.dimension }
        let samples = (0..<dimension * numRows).map(generateValue(value))
        return try! MKSensorData(types: types, start: 0, samplesPerSecond: samplesPerSecond, samples: samples)
    }
    
}
