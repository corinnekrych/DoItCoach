//
//  ExtensionDelegate.swift
//  DoItCoach WatchKit App Extension
//
//  Created by Corinne Krych on 09/04/16.
//  Copyright © 2016 corinnekrych. All rights reserved.
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    var session : WCSession!
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
        if let task = applicationContext["task"] as? [String : AnyObject] {
            if let name = task["name"] as? String,
               let startDate = task["startDate"] as? Double {
                let tasksFound = TasksManager.instance.tasks?.filter{$0.name == name}
                let task: TaskActivity?
                if let tasksFound = tasksFound where tasksFound.count > 0 {
                    task = tasksFound[0] as TaskActivity
                    task?.startDate = NSDate(timeIntervalSinceReferenceDate: startDate)
                    dispatch_async(dispatch_get_main_queue()) { // send notif in foregroung to ntfiy ui if app running
                        print("Notify CurrentTaskStarted")
                        NSNotificationCenter.defaultCenter().postNotificationName("CurrentTaskStarted", object: ["task":task!])
                    }
                }
            }
        }
    }
}
