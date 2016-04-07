//
//  WorkoutSessionService.swift
//  DoItCoach
//
//  Created by Corinne Krych on 05/04/16.
//  Copyright © 2016 corinnekrych. All rights reserved.
//

import Foundation
import HealthKit

protocol WorkoutSessionServiceDelegate: class {
    /// This method is called when an HKWorkoutSession is correctly started
    func workoutSessionService(service: WorkoutSessionService, didStartWorkoutAtDate startDate: NSDate)
    
    /// This method is called when an HKWorkoutSession is correctly stopped
    func workoutSessionService(service: WorkoutSessionService, didStopWorkoutAtDate endDate: NSDate)
    
    /// This method is called when a workout is successfully saved
    func workoutSessionServiceDidSave(service: WorkoutSessionService)
    
    /// This method is called when an anchored query receives new heart rate data
    func workoutSessionService(service: WorkoutSessionService, didUpdateHeartrate heartRate:Double)
    
    /// This method is called when an anchored query receives new distance data
    func workoutSessionService(service: WorkoutSessionService, didUpdateDistance distance:Double)
    
    /// This method is called when an anchored query receives new energy data
    func workoutSessionService(service: WorkoutSessionService, didUpdateEnergyBurned energy:Double)
}

class WorkoutSessionService: NSObject {
    private let healthService = HealthKitManager.instance
    var session: HKWorkoutSession
    let delegate: WorkoutSessionServiceDelegate? = nil
    var task: TaskActivity
    
    // Samples
    var energyData: [HKQuantitySample] = [HKQuantitySample]()
    var hrData: [HKQuantitySample] = [HKQuantitySample]()
    var distanceData: [HKQuantitySample] = [HKQuantitySample]()
    
    // Query Management
    private var queries: [HKQuery] = [HKQuery]()
    internal var distanceAnchorValue:HKQueryAnchor?
    internal var hrAnchorValue:HKQueryAnchor?
    internal var energyAnchorValue:HKQueryAnchor?
    
    // Current Workout Values
    var energyBurned: HKQuantity
    var distance: HKQuantity
    var heartRate: HKQuantity
    
    init(task: TaskActivity) {
        session = HKWorkoutSession(activityType: .Walking,
            locationType: .Outdoor)
        self.task = task
        energyBurned = HKQuantity(unit: energyUnit, doubleValue: 0.0)
        distance = HKQuantity(unit: distanceUnit, doubleValue: 0.0)
        heartRate = HKQuantity(unit: heartRateUnit, doubleValue: 0.0)
        super.init()
        session.delegate = self
    }
    
    func startSession() {
        guard let store = healthService.healthStore else {return}
        store.startWorkoutSession(session)
    }
    
    func stopSession() {
        guard let store = healthService.healthStore else {return}
        store.endWorkoutSession(session)
    }
    
    func saveSession() {
        healthService.saveWorkout(task, workoutService: self) { success, error in
            if success {
                self.delegate?.workoutSessionServiceDidSave(self)
            }
        }
    }
}
extension WorkoutSessionService: HKWorkoutSessionDelegate {
    func workoutSession(workoutSession: HKWorkoutSession,
        didChangeToState toState: HKWorkoutSessionState,
        fromState: HKWorkoutSessionState, date: NSDate) {
            
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                switch toState {
                case .Running:
                    self.sessionStarted(date)
                case .Ended:
                    self.sessionEnded(date)
                default:
                    print("Something weird happened. Not a valid state")
                }
            }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession,
        didFailWithError error: NSError) {
            sessionEnded(NSDate())
    }
    // MARK: Internal Session Control
    private func sessionStarted(date: NSDate) {
        guard let store = healthService.healthStore else {return}
        // Create and Start Queries
        queries.append(distanceQuery(withStartDate: date))
        queries.append(heartRateQuery(withStartDate: date))
        queries.append(energyQuery(withStartDate: date))
        
        for query in queries {
            store.executeQuery(query)
        }
        
        //startDate = date
        
        // Let the delegate know
        delegate?.workoutSessionService(self, didStartWorkoutAtDate: date)
    }
    
    private func sessionEnded(date: NSDate) {
        guard let store = healthService.healthStore else {return}
        // Stop Any Queries
        for query in queries {
            store.stopQuery(query)
        }
        queries.removeAll()
        
        //endDate = date
        
        // Let the delegate know
        self.delegate?.workoutSessionService(self, didStopWorkoutAtDate: date)
    }
}


extension WorkoutSessionService {
    
    internal func heartRateQuery(withStartDate start: NSDate) -> HKQuery {
        // Query all samples from the beginning of the workout session
        let predicate = HKQuery.predicateForSamplesWithStartDate(start, endDate: nil, options: .None)
        
        let query:HKAnchoredObjectQuery = HKAnchoredObjectQuery(type: heartRateType!,
            predicate: predicate,
            anchor: hrAnchorValue,
            limit: Int(HKObjectQueryNoLimit)) {
                (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
                
                self.hrAnchorValue = newAnchor
                self.newHRSamples(sampleObjects)
        }
        
        query.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.hrAnchorValue = newAnchor
            self.newHRSamples(samples)
        }
        
        return query
    }
    
    private func newHRSamples(samples: [HKSample]?) {
        // Abort if the data isn't right
        guard let samples = samples as? [HKQuantitySample] where samples.count > 0 else {
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.hrData += samples
            if let hr = samples.last?.quantity {
                self.heartRate = hr
                self.delegate?.workoutSessionService(self, didUpdateHeartrate: hr.doubleValueForUnit(heartRateUnit))
            }
        }
    }
    
    internal func distanceQuery(withStartDate start: NSDate) -> HKQuery {
        // Query all samples from the beginning of the workout session
        let predicate = HKQuery.predicateForSamplesWithStartDate(start, endDate: nil, options: .None)
        
        let query = HKAnchoredObjectQuery(type: distanceWalkedType!,
            predicate: predicate,
            anchor: distanceAnchorValue,
            limit: Int(HKObjectQueryNoLimit)) {
                (query, samples, deleteObjects, anchor, error) -> Void in
                
                self.distanceAnchorValue = anchor
                self.newDistanceSamples(samples)
        }
        
        query.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.distanceAnchorValue = newAnchor
            self.newDistanceSamples(samples)
        }
        return query
    }
    
    internal func newDistanceSamples(samples: [HKSample]?) {
        // Abort if the data isn't right
        guard let samples = samples as? [HKQuantitySample] where samples.count > 0 else {
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.distance = self.distance.addSamples(samples, unit: distanceUnit)
            self.distanceData += samples
            
            self.delegate?.workoutSessionService(self, didUpdateDistance: self.distance.doubleValueForUnit(distanceUnit))
        }
    }
    
    internal func energyQuery(withStartDate start: NSDate) -> HKQuery {
        // Query all samples from the beginning of the workout session
        let predicate = HKQuery.predicateForSamplesWithStartDate(start, endDate: nil, options: .None)
        
        let query = HKAnchoredObjectQuery(type: energyType!,
            predicate: predicate,
            anchor: energyAnchorValue,
            limit: 0) {
                (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
                
                self.energyAnchorValue = newAnchor
                self.newEnergySamples(sampleObjects)
        }
        
        query.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.energyAnchorValue = newAnchor
            self.newEnergySamples(samples)
        }
        
        return query
    }
    
    internal func newEnergySamples(samples: [HKSample]?) {
        // Abort if the data isn't right
        guard let samples = samples as? [HKQuantitySample] where samples.count > 0 else {
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.energyBurned = self.energyBurned.addSamples(samples, unit: energyUnit)
            self.energyData += samples
            
            self.delegate?.workoutSessionService(self, didUpdateEnergyBurned: self.energyBurned.doubleValueForUnit(energyUnit))
        }
    }
}

extension HKQuantity {
    
    func addQuantity(quantity: HKQuantity?, unit: HKUnit) -> HKQuantity {
        guard let quantity = quantity else {return self}
        
        let initialQuantityValue = self.doubleValueForUnit(unit)
        let newQuantityValue = quantity.doubleValueForUnit(unit)
        
        return HKQuantity(unit: unit, doubleValue: initialQuantityValue + newQuantityValue)
    }
    
    func addQuantities(quantities: [HKQuantity]?, unit: HKUnit) -> HKQuantity {
        guard let quantities = quantities else {return self}
        
        var accumulatedQuantity: HKQuantity = self
        for quantity in quantities {
            accumulatedQuantity = addQuantity(quantity, unit: unit)
        }
        return accumulatedQuantity
    }
    
    func addSamples(samples: [HKQuantitySample]?, unit: HKUnit) -> HKQuantity {
        guard let samples = samples else {return self}
        
        return addQuantities(samples.map { (sample) -> HKQuantity in
            return sample.quantity
            }, unit: unit)
    }
}