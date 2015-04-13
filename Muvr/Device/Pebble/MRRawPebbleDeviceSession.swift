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
        private let warmupSamples = 5
        private var sampleCount = 0

        init(watch: PBWatch, delegate: MRDeviceSessionDelegate) {
            self.watch = watch
            self.delegate = delegate
            self.updateHandler = watch.appMessagesAddReceiveUpdateHandler(appMessagesReceiveUpdateHandler)
        }
        
        private func appMessagesReceiveUpdateHandler(watch: PBWatch!, data: [NSObject : AnyObject]!) -> Bool {
            if let x = data[adKey] as? NSData {
                sampleCount += 1
                if sampleCount > warmupSamples {
                    delegate.deviceSession(sessionId, sensorDataReceivedFrom: deviceId, atDeviceTime: CACurrentMediaTime(), data: x)
                }
            } else if data[deadKey] != nil {
                delegate.deviceSession(sessionId, endedFrom: deviceId)
            }
            return true
        }

        func stop() {
            watch.appMessagesKill { (w, e) in
                self.delegate.deviceSession(self.sessionId, endedFrom: self.deviceId)
            }
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
    
    func stop() {
        currentSession?.stop()
        currentSession = nil
    }
    
    // MARK: PBPebbleCentral implementation
    
    func pebbleCentral(central: PBPebbleCentral!, watchDidConnect watch: PBWatch!, isNew: Bool) {
        NSLog("Connected %@", watch)
    }
    
    func pebbleCentral(central: PBPebbleCentral!, watchDidDisconnect watch: PBWatch!) {
        NSLog("watchDidDisconnect %@", watch)
    }
}
