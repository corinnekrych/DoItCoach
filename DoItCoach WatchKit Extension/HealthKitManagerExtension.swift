//
//  HealthKitManagerExtension.swift
//  DoItCoach
//
//  Created by Corinne Krych on 07/04/16.
//  Copyright © 2016 corinnekrych. All rights reserved.
//

import Foundation
import HealthKit

extension HealthKitManager {

    /// This function saves a workout from a WorkoutSessionService and its HKWorkoutSession
    /// it is available only on watchOS2
    func saveWorkout(task: TaskActivity, workoutService: WorkoutSessionService,
        completion: (Bool, NSError!) -> Void) {
            guard let start = task.startDate, end = task.endDate else {return}
            guard let store = healthStore else {return}
            
            let workout = HKWorkout(activityType: .Walking,
                startDate: start,
                endDate: end,
                duration: end.timeIntervalSinceDate(start),
                totalEnergyBurned: HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: 10.0),
                totalDistance: HKQuantity(unit: HKUnit.meterUnit(), doubleValue: 10.0),
                device: HKDevice.localDevice(),
                metadata: ["TaskType": task.type.rawValue == 0 ? "Task" : "Break"])
            
            // Collect the sampled data
            var samples: [HKQuantitySample] = [HKQuantitySample]()
            samples += workoutService.hrData
            samples += workoutService.distanceData
            samples += workoutService.energyData
            print("Save workout 1")
            // Save the workout
            store.saveObject(workout) { success, error in
                if (!success || samples.count == 0) {
                    completion(success, error)
                    return
                }
                print("Save workout 2")
                // If there are samples to save, add them to the workout
                store.addSamples(samples, toWorkout: workout, completion: { success, error  in
                    print("Save workout 3")
                    completion(success, error)
                })
            }
    }

}