import Foundation
import PebbleKit

protocol MKPebbleDeviceDelegate {
    
    ///
    /// Called when the watch gets disconnected
    ///
    func watchDisconnected()
}

public class MKPebbleConnectivity : NSObject, PBPebbleCentralDelegate, PBWatchDelegate, MKPebbleDeviceDelegate, MKDeviceConnectivity {
    private let central = PBPebbleCentral.defaultCentral()
    private var currentSession: MKPebbleDeviceSession?
    private let sensorDataConnectivityDelegate: MKSensorDataConnectivityDelegate
    
    /// all sessions
    private(set) public var sessions: [MKExerciseConnectivitySession] = []
    /// The delegate that will receive session calls
    public let exerciseConnectivitySessionDelegate: MKExerciseConnectivitySessionDelegate
    /// indicates when the watch is reachable
    private(set) public var reachable: Bool = false
    
    ///
    /// MessageKeyDecoder
    ///
    private struct MessageKeyDecoder {
        enum DecodedKey {
            // INCOMMING
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
        
        // INCOMMING
        private static let deadKey                = NSNumber(uint32: 0xdead0000)
        private static let adKey                  = NSNumber(uint32: 0xad000000)
        private static let acceptedKey            = NSNumber(uint32: 0x01000000)
        private static let timedOutKey            = NSNumber(uint32: 0x02000000)
        private static let rejectedKey            = NSNumber(uint32: 0x03000000)
        private static let trainingCompletedKey   = NSNumber(uint32: 0x04000000)
        private static let exerciseCompletedKey   = NSNumber(uint32: 0x05000000)
        private static let countKey               = NSNumber(uint32: 0x0c000000)
        
        // OUTGOING
        private static let startRecording: UInt32         = 0xb0000000
        private static let stopRecording: UInt32          = 0xb0000001
        
        private static let classificationEstimate: UInt32 = 0xa0000004
        
        mutating func decode(dict: [NSNumber : AnyObject]) -> DecodedKey {
            
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
    private class MKPebbleDeviceSession {
        private var updateHandler: AnyObject?
        private let watch: PBWatch!
        private var session: MKExerciseConnectivitySession!
        private var deviceHandler: MKPebbleDeviceDelegate!
        private let sensorDataConnectivityDelegate: MKSensorDataConnectivityDelegate
        private let exerciseConnectivitySessionDelegate: MKExerciseConnectivitySessionDelegate
        
        private var mkd = MessageKeyDecoder()
        
        init(watch: PBWatch, sensorDataConnectivityDelegate: MKSensorDataConnectivityDelegate, exerciseConnectivitySessionDelegate: MKExerciseConnectivitySessionDelegate, deviceDelegate: MKPebbleDeviceDelegate) {
            self.watch = watch
            self.deviceHandler = deviceDelegate
            self.sensorDataConnectivityDelegate = sensorDataConnectivityDelegate
            self.exerciseConnectivitySessionDelegate = exerciseConnectivitySessionDelegate
            self.session = nil
            
            self.updateHandler = watch.appMessagesAddReceiveUpdateHandler(appMessagesReceiveUpdateHandler)
        }
        
        private func appMessagesReceiveUpdateHandler(watch: PBWatch!, data: [NSNumber : AnyObject]!) -> Bool {
            switch mkd.decode(data) {
            case .Duplicate:
                print("Duplicate")
                break
            case .Undefined:
                print("Undefined")
                break
            case .AccelerometerData(data: let data):
                handleAccelerometerData(CACurrentMediaTime(), data: data)
                break
            case .Accepted:
                //                delegate.deviceSession(sessionId, exerciseAccepted: index, from: deviceId)
                print("Accepted")
                break
            case .Rejected:
                //                delegate.deviceSession(sessionId, exerciseRejected: index, from: deviceId)
                print("rejected")
                break
            case .TimedOut:
                //                delegate.deviceSession(sessionId, exerciseSelectionTimedOut: index, from: deviceId)
                print("timed out")
                break
            case .TrainingCompleted:
                //                delegate.deviceSession(sessionId, exerciseTrainingCompletedFrom: deviceId)
                print("training completed")
                if let session = self.session {
                    stop(session)
                }
                break
            case .ExerciseCompleted:
                //                delegate.deviceSession(sessionId, exerciseCompletedFrom: deviceId)
                print("exercise completed")
                break
            case .Dead:
                print("Watch died! Stopping current session.")
                if let session = self.session {
                    stop(session)
                }
                deviceHandler.watchDisconnected()
                break
            }
            
            return true
        }
        
        
        func handleAccelerometerData(atDeviceTime: CFTimeInterval, data: NSData) {
            do {
                if self.session != nil {
                    let new = try MKSensorData(decoding: data)
                    if self.session.sensorData != nil {
                        try self.session.sensorData!.append(new)
                    } else {
                        // Record timestamp
                        self.session.realStart = NSDate()
                        self.session.sensorData = new
                        self.session.sensorData!.delay = self.session.realStart?.timeIntervalSinceDate(self.session.start)
                    }
                    sensorDataConnectivityDelegate.sensorDataConnectivityDidReceiveSensorData(accumulated: session.sensorData!, new: new, session: session)
                    NSLog("\(atDeviceTime) with \(new.duration); now accumulated \(session.sensorData!.duration)")
                } else {
                    NSLog("\(atDeviceTime) Ignored incomming data because session is nil.")
                }
            } catch {
                NSLog("\(error)")
            }
        }
        
        func start(session: MKExerciseConnectivitySession) {
            self.session = session
            send(MessageKeyDecoder.startRecording)
            exerciseConnectivitySessionDelegate.exerciseConnectivitySessionDidStart(session: session)
        }
        
        func exerciseStarted(exercise: MKExerciseDetail, start: NSDate){
            self.session.currentExerciseStart = start
        }
        
        private func stop(session: MKExerciseConnectivitySession) {
            exerciseConnectivitySessionDelegate.exerciseConnectivitySessionDidEnd(session: session)
            self.session = nil
        }
        
        func stopCurrentSessionAndNotifyWatch() {
            if let session = self.session {
                send(MessageKeyDecoder.stopRecording)
                stop(session)
            }
        }
        
        func send(key: UInt32) {
            let dict: [NSNumber : AnyObject] = [NSNumber(uint32: key) : NSNumber(uint8: 0)]
            watch.appMessagesPushUpdate(dict, onSent: { (watch, _, err) -> Void in
                if err != nil {
                    NSLog("Send failed %@. Retrying.", err!)
                    self.send(key)
                }
            })
        }
        
        func send(key: UInt32, data: NSData) {
            let dict: [NSNumber : AnyObject] = [NSNumber(uint32: key) : data]
            watch.appMessagesPushUpdate(dict, onSent: { (watch, _, err) -> Void in
                if err != nil {
                    NSLog("Send failed %@. Retrying.", err!)
                    self.send(key, data: data)
                }
            })
        }
    }
    
    public init(sensorDataConnectivityDelegate: MKSensorDataConnectivityDelegate, exerciseConnectivitySessionDelegate: MKExerciseConnectivitySessionDelegate) {
        self.sensorDataConnectivityDelegate = sensorDataConnectivityDelegate
        self.exerciseConnectivitySessionDelegate = exerciseConnectivitySessionDelegate
        
        super.init()
        
        let uuid = NSUUID(UUIDString: "E113DED8-0EA6-4397-90FA-CE40941F7CBC")
        central.appUUID = uuid
        central.delegate = self
        central.run()
        
        NSLog("Waiting for Pebble...")
        for _ in 0..<10 {
            if central.connectedWatches.count > 0 { break }
            NSThread.sleepForTimeInterval(0.5)
        }
        NSLog("Done waiting.")
    }
    
    // MARK: Device implementation
    
    ///
    /// Starts a session
    ///
    public func startSession(session: MKExerciseSession) {
        let connectivitySession = MKExerciseConnectivitySession(id: session.id, start: NSDate(), end: nil, last: false, exerciseType: session.exerciseType)
        if currentSession == nil {
            if central.connectedWatches.count > 1 {
                NSLog("Too many Pebbles connected!")
                return
            } else if central.connectedWatches.count == 0 {
                NSLog("No Pebble connected!")
                return
            } else {
                let watch = central.lastConnectedWatch()!
                watch.appMessagesLaunch { (watch, error) in
                    self.currentSession = MKPebbleDeviceSession(watch: watch, sensorDataConnectivityDelegate: self.sensorDataConnectivityDelegate, exerciseConnectivitySessionDelegate: self.exerciseConnectivitySessionDelegate, deviceDelegate: self)
                    
                    self.currentSession?.start(connectivitySession)
                }
            }
        } else if session.id != self.currentSession?.session?.id {
            // Make sure there is no previous session running
            self.currentSession?.stopCurrentSessionAndNotifyWatch()
            self.currentSession?.start(connectivitySession)
        }
    }
    
    ///
    /// Call back when an excercise is started
    ///
    public func exerciseStarted(exercise: MKExerciseDetail, start: NSDate){
        currentSession?.exerciseStarted(exercise, start: start)
    }
    
    ///
    /// Stops the currently running session
    ///
    public func endSession(session: MKExerciseSession) {
        
        if currentSession?.session?.id == session.id {
            currentSession?.stopCurrentSessionAndNotifyWatch()
        } else {
            NSLog("Trying to stop a session on Pebble that is not active on the phone.")
        }
    }
    
    ///
    /// Stops the currently running session
    ///
    public func watchDisconnected() {
        self.currentSession = nil
    }
    
    ///
    /// Indicates whether the device is running
    ///
    var running: Bool {
        return currentSession != nil
    }
    
    // MARK: PBPebbleCentral implementation
    
    public func pebbleCentral(central: PBPebbleCentral, watchDidConnect watch: PBWatch, isNew: Bool) {
        reachable = true
        NSLog("Connected %@", watch)
    }
    
    public func pebbleCentral(central: PBPebbleCentral, watchDidDisconnect watch: PBWatch) {
        reachable = false
        NSLog("Pebble watchDidDisconnect %@", watch)
    }
}