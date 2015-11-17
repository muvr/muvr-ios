///
/// The sensor data type
///
public enum MKSensorDataType : Equatable {
    case Accelerometer(location: Location)
    case Gyroscope(location: Location)
    case HeartRate
    
    /// The enumeration of where a sensor data is coming from
    public enum Location : Equatable {
        /// the left wrist
        case LeftWrist
        /// the right wrist
        case RightWrist
    }
    
    
    ///
    /// The required dimension of the data
    ///
    var dimension: Int {
        switch self {
        case .Accelerometer(_): return 3
        case .Gyroscope(_): return 3
        case .HeartRate: return 1
        }
    }
}

public func ==(lhs: MKSensorDataType, rhs: MKSensorDataType) -> Bool {
    switch (lhs, rhs) {
    case (.Accelerometer(let ll), .Accelerometer(let rl)): return ll == rl
    case (.Gyroscope(let ll), .Gyroscope(let rl)): return ll == rl
    case (.HeartRate, .HeartRate): return true
    default: return false
    }
}

public func ==(lhs: MKSensorDataType.Location, rhs: MKSensorDataType.Location) -> Bool {
    switch (lhs, rhs) {
    case (.LeftWrist, .LeftWrist): return true
    case (.RightWrist, .RightWrist): return true
    default: return false
    }
}

