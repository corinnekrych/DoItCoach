//
//  ExtensionDelegate.swift
//  Pom WatchKit Extension
//
//  Created by Corinne Krych on 26/02/16.
//  Copyright © 2016 corinne. All rights reserved.
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    var session: WCSession!
    let tasksMgr = TasksManager.instance
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        if (WCSession.isSupported()) {
            session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

}
// MARK: WCSessionDelegate
extension ExtensionDelegate: WCSessionDelegate {
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        print("Received application context \(applicationContext)")
        if let tasks = applicationContext["tasks"] as? [[String : AnyObject]] {
            let tasks = tasks.map({ (task: [String : AnyObject]) -> TaskActivity in
                if let name = task["name"] as? String, let duration = task["duration"] as? Double, let type = task["type"] as? Int {
                    return TaskActivity(name: name,
                        duration: NSTimeInterval(duration),
                        startDate: nil, endDate: nil,
                        type: TaskType(rawValue: type)!,
                        manager: TasksManager.instance)
                }
                return TaskActivity(name: "TODO", duration: NSTimeInterval(10), manager: TasksManager.instance)
            })
            
            tasksMgr.remainingTasks = tasks //update list in background
            dispatch_async(dispatch_get_main_queue()) { //update list in foregroung if app running
                NSNotificationCenter.defaultCenter().postNotificationName("TasksUpdated", object: nil)
            }
        } else if let task = applicationContext["task"] as? [String : AnyObject] {
            print("INSIDE1 \(task)")
            if let name = task["name"] as? String,
                let duration = task["duration"] as? Double,
                let type = task["type"] as? Int,
                let startDate = task["startDate"] as? Double {
                    
                    // TODO when task started from app no animation displayeddis
                    print("INSIDE2 \(name)")
                    let taskObject = TaskActivity(name: name,
                        duration: NSTimeInterval(duration),
                        startDate: NSDate(timeIntervalSinceReferenceDate: startDate),
                        endDate: nil,
                        type: TaskType(rawValue: type)!,
                        manager: tasksMgr)
                    let tasksFound = tasksMgr.tasks?.filter{$0.name == name}
                    print("INSIDE3 \(tasksFound)")
                    if let tasksFound = tasksFound where tasksFound.count > 0 {
                        print("INSIDE4 update task start date \(tasksFound)")
                        tasksFound[0].startDate = NSDate(timeIntervalSinceReferenceDate: startDate) // update task in background
                    }
        
                    dispatch_async(dispatch_get_main_queue()) { // send notif in foregroung to ntfiy ui if app running
                        print("Notify CurrentTaskStarted")
                        NSNotificationCenter.defaultCenter().postNotificationName("CurrentTaskStarted", object: ["task":taskObject])
                         print("INSIDE5")
                   }
                    
                   print("INSIDE6")
            }
        }
    }
}