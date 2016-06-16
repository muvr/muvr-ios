//
//  MRWorkoutSessionDelegate.swift
//  Muvr
//
//  Created by Damien Bailly on 25/11/2015.
//  Copyright © 2015 Muvr. All rights reserved.
//
import HealthKit
import MuvrKit

public final class MRWorkoutSessionDelegate: NSObject, HKWorkoutSessionDelegate {

    private lazy var healthStore: HKHealthStore = {
        return HKHealthStore()
    }()
    
    private var workoutSession: HKWorkoutSession? = nil
    private var exerciseType: MKExerciseType? = nil
    private var start: Date? = nil
    private var end: Date? = nil
    
    /// HK running queries
    private var queries: [HKQuery] = []
    
    /// The current heartrate
    private(set) var heartrate: Double? = nil
    /// The active energy burned during the session
    private(set) var energyBurned: Double? = nil

    func authorise() {
        // Only proceed if health data is available.
        guard HKHealthStore.isHealthDataAvailable() else {
            NSLog("HealthKit not available")
            return
        }
        // Ask for permission
        let typesToShare: Set<HKSampleType> = [HKSampleType.workoutType()]
        let typesToRead: Set<HKSampleType> = [
            HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
            HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        ]
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                NSLog("HealthKit authorised")
            } else {
                NSLog("Failed to get HealthKit authorisation: \(error)")
            }
        }
    }
    
    func startSession(start: Date, exerciseType type: MKExerciseType) {
        // Only proceed if health data is available.
        guard HKHealthStore.isHealthDataAvailable() else {
            NSLog("HealthKit not available")
            return
        }
        // Start workout session
        let workoutSession = HKWorkoutSession(activityType: .traditionalStrengthTraining, locationType: .indoor)
        workoutSession.delegate = self
        resetSession()
        self.start = start
        self.healthStore.start(workoutSession)
        self.workoutSession = workoutSession
        self.exerciseType = type
    }
    
    func stopSession(end: Date) {
        // Only proceed if health data is available.
        guard HKHealthStore.isHealthDataAvailable() else {
            NSLog("HealthKit not available")
            return
        }
        self.end = end
        if let workoutSession = workoutSession {
            healthStore.end(workoutSession)
        }
    }
    
    /// create the queries running during a workout
    private func createQueries() -> [HKQuery] {
        guard let start = start else { return [] }
        let startDatePredicate = HKQuery.predicateForSamples(withStart: start, end: nil, options: HKQueryOptions())
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let predicate = CompoundPredicate(andPredicateWithSubpredicates: [startDatePredicate, devicePredicate])
        
        /// callback - record the latest heartrate value
        func updateHeartrate(_ samples: [HKSample]?) {
            // TODO dispatch to main queue
            let heartrateUnit = HKUnit(from: "count/min")
            guard let heartrateSamples = samples as? [HKQuantitySample] where !heartrateSamples.isEmpty else { return }
            let hr = heartrateSamples[heartrateSamples.count - 1].quantity.doubleValue(for: heartrateUnit)
            heartrateSamples.forEach { sample in
                let value = sample.quantity.doubleValue(for: heartrateUnit)
                NSLog("Heartrate \(value) from \(sample.startDate) to \(sample.endDate)")
            }
            self.heartrate = hr
            NSLog("Heartrate: \(hr)")
        }
        
        /// callback - record the total energy burned during session
        func updateEnergyBurned(_ samples: [HKSample]?) {
            // TODO dispatch to main queue
            let energyUnit = HKUnit.kilocalorie()
            guard let activeEnergyBurnedSamples = samples as? [HKQuantitySample] else { return }
            let eb = activeEnergyBurnedSamples.reduce(self.energyBurned ?? 0.0) { energy, sample in
                let value = sample.quantity.doubleValue(for: energyUnit)
                NSLog("Energy burned \(value) kCal from \(sample.startDate) to \(sample.endDate)")
                return energy + value
            }
            self.energyBurned = eb
            NSLog("Active energy burned: \(eb) kCal")
        }
        
        /// create a query to get heartbeat samples from healthkit
        func createHeartrateQuery() -> HKQuery? {
            guard let heartrateType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
                NSLog("Heartrate type not available")
                return nil
            }
            let heartrateQuery = HKAnchoredObjectQuery(type: heartrateType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) {
                (query, samples, deletedObjects, anchor, error) -> Void in updateHeartrate(samples)
            }
            heartrateQuery.updateHandler = {
                (query, samples, deletedObjects, anchor, error) -> Void in updateHeartrate(samples)
            }
            return heartrateQuery
        }
        
        /// create a query to get active energy burned samples from healthkit
        func createEnergyBurnedQuery() -> HKQuery? {
            guard let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned) else {
                NSLog("Active energy burned type not available")
                return nil
            }
            let activeEnergyBurnedQuery = HKAnchoredObjectQuery(type: activeEnergyBurnedType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) {
                query, samples, deletedObjects, anchor, error in updateEnergyBurned(samples)
            }
            activeEnergyBurnedQuery.updateHandler = {
                query, samples, deletedObjects, anchor, error in updateEnergyBurned(samples)
            }
            return activeEnergyBurnedQuery
        }

        return [createHeartrateQuery(), createEnergyBurnedQuery()].flatMap { return $0 }
    }
    
    /// save workout into healthkit
    private func saveWorkout() {
        guard let start = start, let exerciseType = exerciseType, let end = end else {
            NSLog("Incomplete workout")
            return
        }
        if healthStore.authorizationStatus(for: HKObjectType.workoutType()) != .sharingAuthorized {
            NSLog("Healthkit saving workout not authorised")
            return
        }
        let totalEnergyBurned = energyBurned.map { HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: $0) }
        let duration = end.timeIntervalSince(start)
        let workout = HKWorkout(activityType: HKWorkoutActivityType.TraditionalStrengthTraining, startDate: start, endDate: end, duration: duration, totalEnergyBurned: totalEnergyBurned, totalDistance: nil, metadata: ["type": exerciseType.title])
        healthStore.saveObject(workout) { success, error in
            if let error = error where !success {
                NSLog("Failed to save workout: \(error)")
                return
            }
            NSLog("Workout saved to healthkit")
        }
    }
    
    /// reset session data
    private func resetSession() {
        self.workoutSession = nil
        self.start = nil
        self.end = nil
        self.exerciseType = nil
        self.heartrate = nil
        self.energyBurned = nil
    }
    
    /// callback - begin workout session
    func beginWorkoutSession(_ onDate: Date) {
        self.queries = createQueries()
        self.queries.forEach { query in
            healthStore.execute(query)
        }
    }
    
    /// callback - terminate workout session
    func endWorkoutSession() {
        // Stop running queries
        self.queries.forEach { query in
            healthStore.stop(query)
        }
        saveWorkout()
        resetSession()
    }
    
    /// MARK: HKWorkoutSessionDelegate
    
    public func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:  self.beginWorkoutSession(date)
        case .ended: self.endWorkoutSession()
        default: NSLog("Unexpected workout sessions state: \(toState)")
        }
    }
    
    public func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
        NSLog("Workout session failed: \(error)")
    }
    
}
