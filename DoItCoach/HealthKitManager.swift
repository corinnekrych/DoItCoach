//
//  HealthKitManager.swift
//  DoItCoach
//
//  Created by Corinne Krych on 04/04/16.
//  Copyright © 2016 corinnekrych. All rights reserved.
//

import Foundation
import HealthKit

let workoutType = HKObjectType.workoutType()
let heartRateType =  HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
let distanceWalkedType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)
let energyType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)
let heartRateUnit = HKUnit(fromString: "count/min")
let distanceUnit: HKUnit = HKUnit.meterUnit()
let energyUnit = HKUnit.kilocalorieUnit()

public class HealthKitManager {
    
    public static let instance = HealthKitManager()
    
    public var healthStore: HKHealthStore? = {
        if HKHealthStore.isHealthDataAvailable() {
            return HKHealthStore()
        } else {
            return nil
        }
    }()
    
   
    public func authorizeHealthKitAccess(completion: ((success:Bool, error:NSError!) -> Void)!) {
        let dataTypesToRead: Set<HKObjectType> = Set(arrayLiteral: heartRateType!, distanceWalkedType!, energyType!, workoutType)
        let dataTypesToWrite: Set<HKSampleType> = Set(arrayLiteral: heartRateType!, distanceWalkedType!, energyType!, workoutType)
        healthStore?.requestAuthorizationToShareTypes(dataTypesToWrite, readTypes: dataTypesToRead, completion: { (success, error) in
            completion(success: success, error: error)
        })
    }
}