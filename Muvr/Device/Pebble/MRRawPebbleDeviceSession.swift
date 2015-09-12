import Foundation

class MRRawPebbleConnectedDevice : NSObject, PBPebbleCentralDelegate, PBWatchDelegate {
    private let central = PBPebbleCentral.defaultCentral()
    private var currentSession: MRPebbleDeviceSession?
    
    private struct MessageDataEncoder {
        
        static func formatMRResistanceExercises(exercises: [MRClassifiedResistanceExercise]) -> NSData {
            assert(exercises.count < 5, "The sets must be < 5")
            
            let data = NSMutableData()
            // (#define APP_MESSAGE_INBOX_SIZE_MINIMUM 124) / 29 == 4
            exercises.take(4).forEach { ce -> Void in
                let re = NSMutableData(length: sizeof(resistance_exercise_t))!
                let name = UnsafePointer<Int8>(ce.resistanceExercise.title.cStringUsingEncoding(NSASCIIStringEncoding)!)
                mk_resistance_exercise(re.mutableBytes, name, UInt8(ce.confidence * 100), 0, 0, 0)
                data.appendData(re)
            }
            
            assert(data.length <= 124, "Too much data to send over BLE.")
            return data
        }
        
    }
    
    ///
    /// MessageKeyDecoder
    ///
    private struct MessageKeyDecoder {
        enum DecodedKey {
            case Duplicate
            case Undefined
            case Dead
            case AccelerometerData(data: NSData)
            case Accepted(index: UInt8)
            case Rejected(index: UInt8)
            case TimedOut(index: UInt8)
            case TrainingCompleted
            case ExerciseCompleted
        }
        
        private var count: UInt32 = UInt32.max
        
        private static let deadKey              = NSNumber(uint32: 0xdead0000)
        private static let adKey                = NSNumber(uint32: 0xad000000)
        private static let acceptedKey          = NSNumber(uint32: 0x01000000)
        private static let timedOutKey          = NSNumber(uint32: 0x02000000)
        private static let rejectedKey          = NSNumber(uint32: 0x03000000)
        private static let trainingCompletedKey = NSNumber(uint32: 0x04000000)
        private static let exerciseCompletedKey = NSNumber(uint32: 0x05000000)
        private static let countKey             = NSNumber(uint32: 0x0c000000)
        
        mutating func decode(dict: [NSObject : AnyObject]) -> DecodedKey {
            
            if let msgCount = dict[MessageKeyDecoder.countKey] as? NSNumber {
                print("reported count = \(msgCount), our count = \(count)");
                if msgCount.unsignedIntValue == count {
                    print("Duplicate")
                    count = msgCount.unsignedIntValue
                    return DecodedKey.Duplicate
                }
                count = msgCount.unsignedIntValue
            }
            
            for (k, rawValue) in dict {
                if let data = rawValue as? NSData {
                    let b = UnsafePointer<UInt8>(data.bytes)
                    switch k {
                    case MessageKeyDecoder.deadKey: return DecodedKey.Dead
                    case MessageKeyDecoder.adKey: return DecodedKey.AccelerometerData(data: data)
                    case MessageKeyDecoder.acceptedKey: return DecodedKey.Accepted(index: b.memory)
                    case MessageKeyDecoder.rejectedKey: return DecodedKey.Rejected(index: b.memory)
                    case MessageKeyDecoder.timedOutKey: return DecodedKey.TimedOut(index: b.memory)
                    case MessageKeyDecoder.trainingCompletedKey: return DecodedKey.TrainingCompleted
                    case MessageKeyDecoder.exerciseCompletedKey: return DecodedKey.ExerciseCompleted
                    case MessageKeyDecoder.countKey: continue
                    default: return .Undefined
                    }
                }
            }
            
            return .Undefined
        }
    }

    ///
    /// Pebble device session
    ///
    private class MRPebbleDeviceSession {
        private let delegate: MRDeviceSessionDelegate!
        private var updateHandler: AnyObject?
        private let watch: PBWatch!
        private let sessionId = DeviceSession()
        private let deviceId = DeviceId()   // TODO: Actual deviceId
        private var mkd = MessageKeyDecoder()

        init(watch: PBWatch, delegate: MRDeviceSessionDelegate) {
            self.watch = watch
            self.delegate = delegate
            self.updateHandler = watch.appMessagesAddReceiveUpdateHandler(appMessagesReceiveUpdateHandler)
        }
        
        private func appMessagesReceiveUpdateHandler(watch: PBWatch!, data: [NSObject : AnyObject]!) -> Bool {
            switch mkd.decode(data) {
            case .Duplicate:
                print("Duplicate")
                break
            case .Undefined:
                print("Undefined")
                break
            case .AccelerometerData(data: let data):
                delegate.deviceSession(sessionId, sensorDataReceivedFrom: deviceId, atDeviceTime: CACurrentMediaTime(), data: data)
                break
            case .Accepted(index: let index):
                delegate.deviceSession(sessionId, exerciseAccepted: index, from: deviceId)
                break
            case .Rejected(index: let index):
                delegate.deviceSession(sessionId, exerciseRejected: index, from: deviceId)
                break
            case .TimedOut(index: let index):
                delegate.deviceSession(sessionId, exerciseSelectionTimedOut: index, from: deviceId)
                break
            case .TrainingCompleted:
                delegate.deviceSession(sessionId, exerciseTrainingCompletedFrom: deviceId)
                break
            case .ExerciseCompleted:
                delegate.deviceSession(sessionId, exerciseCompletedFrom: deviceId)
                break
            default:
                fatalError("Match error")
            }
            
            return true
        }

        func stop() {
            watch.appMessagesKill { (w, e) in
                self.delegate.deviceSession(self.sessionId, endedFrom: self.deviceId)
                w.appMessagesRemoveUpdateHandler(self.updateHandler)
            }
        }
        
        func send(key: UInt32) {
            let dict: [NSObject : AnyObject] = [NSNumber(uint32: key) : NSNumber(uint8: 0)]
            watch.appMessagesPushUpdate(dict, onSent: { (watch, _, err) -> Void in
                if err != nil {
                    NSLog("Send failed %@. Retrying.", err)
                    self.send(key)
                }
            })
        }
        
        func send(key: UInt32, data: NSData) {
            let dict: [NSObject : AnyObject] = [NSNumber(uint32: key) : data]
            watch.appMessagesPushUpdate(dict, onSent: { (watch, _, err) -> Void in
                if err != nil {
                    NSLog("Send failed %@. Retrying.", err)
                    self.send(key, data: data)
                }
            })
        }
    }
    
    override init() {
        super.init()
        
        let uuid = NSMutableData(length: 16)!
        NSUUID(UUIDString: "E113DED8-0EA6-4397-90FA-CE40941F7CBC")!.getUUIDBytes(UnsafeMutablePointer(uuid.mutableBytes))
        central.appUUID = uuid
        central.delegate = self
    }
    
    // MARK: Device implementation

    ///
    /// Starts a session
    ///
    func start(deviceSessionDelegate: MRDeviceSessionDelegate, inMode mode: MRMode) {
        if currentSession == nil {
            if central.connectedWatches.count > 1 {
                // TODO: DeviceSessionDelegate.deviceSession:didNotStart
                //return Either.left(NSError.errorWithMessage("Device.Pebble.tooManyWatches".localized(), code: 1))
            } else if central.connectedWatches.count == 0 {
                // TODO: DeviceSessionDelegate.deviceSession:didNotStart
                //return Either.left(NSError.errorWithMessage("Device.Pebble.noWatches".localized(), code: 2))
            } else {
                let watch = central.connectedWatches[0] as! PBWatch
                watch.appMessagesLaunch { (watch, error) in
                    self.currentSession = MRPebbleDeviceSession(watch: watch, delegate: deviceSessionDelegate)
                    switch mode {
                    case .Training(let exercises): self.currentSession?.send(0xb0000000, data: MessageDataEncoder.formatMRResistanceExercises(exercises)); break
                    case .AssistedClassification: self.currentSession?.send(0xb1000000); break
                    case .AutomaticClassification: self.currentSession?.send(0xb2000000); break
                    }
                }
            }
        }
    }
    
    ///
    /// Stops the currently running session
    ///
    func stop() {
        currentSession?.stop()
        currentSession = nil
    }
    
    func notifyClassifying() {
        // TODO: Needed at all?
    }
    
    func notifyExercising() {
        currentSession?.send(0xa0000002)
    }
    
    func notifyNotMoving() {
        currentSession?.send(0xa0000000)
    }
    
    func notifyMoving() {
        currentSession?.send(0xa0000001)
    }
    
    func notifySimpleClassificationCompleted(exercises: [MRClassifiedResistanceExercise]) {
        currentSession?.send(0xa0000003, data: MessageDataEncoder.formatMRResistanceExercises(exercises))
    }
    
    func notifySimpleCurrent(ec: (MRResistanceExercise, Double)) {
        let (exercise, confidence) = ec
        let data = NSMutableData(length: sizeof(resistance_exercise_t))!
        let name = UnsafePointer<Int8>(exercise.title.cStringUsingEncoding(NSASCIIStringEncoding)!)
        mk_resistance_exercise(data.mutableBytes, name, UInt8(confidence * 100), 0, 0, 0)

        assert(data.length <= 124, "Too much data to send over BLE.")
        currentSession?.send(0xa0000004, data: data)
    }
    
    ///
    /// Indicates whether the device is running
    ///
    var running: Bool {
        return currentSession != nil
    }
    
    // MARK: PBPebbleCentral implementation
    
    func pebbleCentral(central: PBPebbleCentral!, watchDidConnect watch: PBWatch!, isNew: Bool) {
        NSLog("Connected %@", watch)
        if currentSession != nil {
            
        }
    }
    
    func pebbleCentral(central: PBPebbleCentral!, watchDidDisconnect watch: PBWatch!) {
        NSLog("watchDidDisconnect %@", watch)
        if currentSession != nil {
            
        }
    }
}
