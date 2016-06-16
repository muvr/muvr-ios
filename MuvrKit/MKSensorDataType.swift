///
/// The sensor data type
///
public enum MKSensorDataType : Equatable {
    case accelerometer(location: Location)
    case gyroscope(location: Location)
    case heartRate
    
    /// The enumeration of where a sensor data is coming from
    public enum Location : Equatable {
        /// the left wrist
        case leftWrist
        /// the right wrist
        case rightWrist
    }
    
    ///
    /// The required dimension of the data
    ///
    var dimension: Int {
        switch self {
        case .accelerometer(_): return 3
        case .gyroscope(_): return 3
        case .heartRate: return 1
        }
    }
}

public func ==(lhs: MKSensorDataType, rhs: MKSensorDataType) -> Bool {
    switch (lhs, rhs) {
    case (.accelerometer(let ll), .accelerometer(let rl)): return ll == rl
    case (.gyroscope(let ll), .gyroscope(let rl)): return ll == rl
    case (.heartRate, .heartRate): return true
    default: return false
    }
}

public func ==(lhs: MKSensorDataType.Location, rhs: MKSensorDataType.Location) -> Bool {
    switch (lhs, rhs) {
    case (.leftWrist, .leftWrist): return true
    case (.rightWrist, .rightWrist): return true
    default: return false
    }
}

