//
//  AppDelegate.swift
//  Pom
//
//  Created by Corinne Krych on 26/02/16.
//  Copyright © 2016 corinne. All rights reserved.
//

import UIKit
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var session : WCSession!
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        if (WCSession.isSupported()) {
            session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
        return true
    }

    
}

extension AppDelegate: WCSessionDelegate {
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        print("RECEIVED ON IOS: \(message)")
        dispatch_async(dispatch_get_main_queue()) {
            if let taskMessage = message["task"] as? [String : AnyObject] {
                if let taskName = taskMessage["name"] as? String {
                    let tasksFiltered = TasksManager.instance.tasks?.filter {$0.name == taskName}
                    guard let tasks = tasksFiltered else {return}
                    let task = tasks[0]
                    if task.isStarted() {
                        replyHandler(["taskId": task.name, "status": "already started"])
                        return
                    }
                    if task.endDate != nil {
                        replyHandler(["taskId": task.name, "status": "already finished"])
                        return
                    }
                    if let endDate = taskMessage["endDate"] as? Double {
                        task.endDate = NSDate(timeIntervalSinceReferenceDate: endDate)
                        replyHandler(["taskId": task.name, "status": "finished ok"])
                        NSNotificationCenter.defaultCenter().postNotificationName("TimerFired", object: ["task":self])
                        
                    } else if let startDate = taskMessage["startDate"] as? Double {
                        task.startDate = NSDate(timeIntervalSinceReferenceDate: startDate)
                        replyHandler(["taskId": task.name, "status": "started ok"])
                    }
                    saveTasks()

                }
            }
        }
    }
}


