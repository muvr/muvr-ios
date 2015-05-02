import Foundation

class MRRawPebbleConnectedDevice : NSObject, PBPebbleCentralDelegate, PBWatchDelegate {
    private let central = PBPebbleCentral.defaultCentral()
    private var currentSession: MRPebbleDeviceSession?
    
    ///
    /// Pebble device session
    ///
    private class MRPebbleDeviceSession {
        private let delegate: MRDeviceSessionDelegate!
        private var updateHandler: AnyObject?
        private let watch: PBWatch!
        private let sessionId = DeviceSession()
        private let deviceId = DeviceId()   // TODO: Actual deviceId
        private let deadKey = NSNumber(uint32: 0x0000dead)
        private let adKey = NSNumber(uint32: 0xface0fb0)
        private let acceptedKey = NSNumber(uint32: 0xb0000003)
        private let timedOutKey = NSNumber(uint32: 0xb1000003)
        private let rejectedKey = NSNumber(uint32: 0xb2000003)
        private let warmupSamples = 5
        private var sampleCount = 0

        init(watch: PBWatch, delegate: MRDeviceSessionDelegate) {
            self.watch = watch
            self.delegate = delegate
            self.updateHandler = watch.appMessagesAddReceiveUpdateHandler(appMessagesReceiveUpdateHandler)
        }
        
        private func appMessagesReceiveUpdateHandler(watch: PBWatch!, data: [NSObject : AnyObject]!) -> Bool {
            for (k, rawValue) in data {
                if let data = rawValue as? NSData {
                    let b = UnsafePointer<UInt8>(data.bytes)
                    switch k {
                    case adKey:
                        sampleCount += 1
                        if sampleCount > warmupSamples {
                            delegate.deviceSession(sessionId, sensorDataReceivedFrom: deviceId, atDeviceTime: CACurrentMediaTime(), data: data)
                        }
                        break
                    case deadKey:
                        delegate.deviceSession(sessionId, endedFrom: deviceId)
                        break
                    case acceptedKey:
                        delegate.deviceSession(sessionId, simpleMessageReceivedFrom: deviceId, key: acceptedKey.uint32Value(), value: b.memory)
                        break
                    case rejectedKey:
                        delegate.deviceSession(sessionId, simpleMessageReceivedFrom: deviceId, key: rejectedKey.uint32Value(), value: b.memory)
                        break
                    case timedOutKey:
                        delegate.deviceSession(sessionId, simpleMessageReceivedFrom: deviceId, key: acceptedKey.uint32Value(), value: b.memory)
                        break
                    default:
                        fatalError("Match error")
                    }
                }
            }
            if let x = data[adKey] as? NSData {
                sampleCount += 1
                if sampleCount > warmupSamples {
                    delegate.deviceSession(sessionId, sensorDataReceivedFrom: deviceId, atDeviceTime: CACurrentMediaTime(), data: x)
                }
            } else if data[deadKey] != nil {
                delegate.deviceSession(sessionId, endedFrom: deviceId)
            }
            // TODO: classified here
            return true
        }

        func stop() {
            watch.appMessagesKill { (w, e) in
                self.delegate.deviceSession(self.sessionId, endedFrom: self.deviceId)
            }
        }
        
        func send(key: UInt32) {
            let dict: [NSObject : AnyObject] = [NSNumber(uint32: key) : NSNumber(uint8: 0)]
            watch.appMessagesPushUpdate(dict, onSent: { (watch, _, _) -> Void in })
        }
        
        func send(key: UInt32, data: NSData) {
            let dict: [NSObject : AnyObject] = [NSNumber(uint32: key) : data]
            watch.appMessagesPushUpdate(dict, onSent: { (watch, _, _) -> Void in })
        }
    }
    
    override init() {
        super.init()
        
        let uuid = NSMutableData(length: 16)!
        NSUUID(UUIDString: "E113DED8-0EA6-4397-90FA-CE40941F7CBC")!.getUUIDBytes(UnsafeMutablePointer(uuid.mutableBytes))
        central.appUUID = uuid
        central.delegate = self
    }
    
    ///
    /// App launched callback from the watch
    ///
    private func appLaunched(deviceSessionDelegate: MRDeviceSessionDelegate, watch: PBWatch!, error: NSError!) {
        let deviceId = watch.serialNumber.md5UUID()
        if error != nil {
            // TODO: DeviceSessionDelegate.deviceSession:didNotStart;
            // deviceDelegate.deviceAppLaunchFailed(deviceId, error: error!)
        } else {
            MRPebbleDeviceSession(watch: watch, delegate: deviceSessionDelegate)
        }
    }
    
    // MARK: Device implementation

    ///
    /// Starts a session
    ///
    func start(deviceSessionDelegate: MRDeviceSessionDelegate) {
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
    
    func notifySimpleClassificationCompleted(simpleClassifiedSets: [MRResistanceExercise]) {
        var data = NSMutableData()
        simpleClassifiedSets.foreach { (x: MRResistanceExercise) -> Void in
            var re = NSMutableData(length: sizeof(resistance_exercise_t))!
            let name = UnsafePointer<Int8>(x.exercise.cStringUsingEncoding(NSASCIIStringEncoding)!)
            mk_resistance_exercise(re.mutableBytes, name, UInt8(x.confidence * 100), 0, 0, 0)
            data.appendData(re)
        }
        
        currentSession?.send(0xa0000003, data: data)
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
    }
    
    func pebbleCentral(central: PBPebbleCentral!, watchDidDisconnect watch: PBWatch!) {
        NSLog("watchDidDisconnect %@", watch)
    }
}
