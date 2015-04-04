import Foundation

class RawPebbleConnectedDevice : NSObject, PBPebbleCentralDelegate, PBWatchDelegate {
    private let central = PBPebbleCentral.defaultCentral()
    
    private class PebbleDeviceSession {
        private let delegate: DeviceSessionDelegate!
        private let updateHandler: AnyObject?
        private let watch: PBWatch!
        private let sessionId = DeviceSession()
        private let deviceId = DeviceId()   // TODO: Actual deviceId
        private let deadKey = NSNumber(uint32: 0x0000dead)
        private let adKey = NSNumber(uint32: 0xface0fb0)

        init(watch: PBWatch, delegate: DeviceSessionDelegate) {
            self.watch = watch
            self.delegate = delegate
            self.updateHandler = watch.appMessagesAddReceiveUpdateHandler(appMessagesReceiveUpdateHandler)
        }
        
        private func appMessagesReceiveUpdateHandler(watch: PBWatch!, data: [NSObject : AnyObject]!) -> Bool {
            if let x = data[adKey] as? NSData {
                delegate.deviceSession(sessionId, sensorDataReceivedFrom: DeviceId(),
                    atDeviceTime: CFAbsoluteTimeGetCurrent(), data: x)
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
    
    func findWatch() -> Either<NSError, PBWatch> {
        if central.connectedWatches.count > 1 {
            return Either.left(NSError.errorWithMessage("Device.Pebble.tooManyWatches".localized(), code: 1))
        } else if central.connectedWatches.count == 0 {
            return Either.left(NSError.errorWithMessage("Device.Pebble.noWatches".localized(), code: 2))
        } else {
            let watch = central.connectedWatches[0] as PBWatch
            return Either.right(watch)
        }
    }

    ///
    /// App launched callback from the watch
    ///
    private func appLaunched(deviceSessionDelegate: DeviceSessionDelegate, watch: PBWatch!, error: NSError!) {
        let deviceId = watch.serialNumber.md5UUID()
        if error != nil {
            // TODO: DeviceSessionDelegate.deviceSession:didNotStart;
            // deviceDelegate.deviceAppLaunchFailed(deviceId, error: error!)
        } else {
            PebbleDeviceSession(watch: watch, delegate: deviceSessionDelegate)
        }
    }
    
    private func appKilled(watch: PBWatch!, error: NSError!) {
    }

    // MARK: Device implementation

    func start(deviceSessionDelegate: DeviceSessionDelegate) {
        if central.connectedWatches.count > 1 {
            // TODO: DeviceSessionDelegate.deviceSession:didNotStart
            //return Either.left(NSError.errorWithMessage("Device.Pebble.tooManyWatches".localized(), code: 1))
        } else if central.connectedWatches.count == 0 {
            // TODO: DeviceSessionDelegate.deviceSession:didNotStart
            //return Either.left(NSError.errorWithMessage("Device.Pebble.noWatches".localized(), code: 2))
        } else {
            let watch = central.connectedWatches[0] as PBWatch
            watch.appMessagesLaunch { (watch, error) in
                PebbleDeviceSession(watch: watch, delegate: deviceSessionDelegate)
                return
            }
        }
    }
    
    func pebbleCentral(central: PBPebbleCentral!, watchDidConnect watch: PBWatch!, isNew: Bool) {
        NSLog("Connected %@", watch)
    }
    
    func pebbleCentral(central: PBPebbleCentral!, watchDidDisconnect watch: PBWatch!) {
        NSLog("watchDidDisconnect %@", watch)
    }
}
