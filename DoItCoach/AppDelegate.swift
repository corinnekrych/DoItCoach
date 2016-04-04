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
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {
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

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}

// MARK: WCSessionDelegate
extension AppDelegate {
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        print("RECEIVED ON IOS: \(message)")
        dispatch_async(dispatch_get_main_queue()) {
            let taskName = message["task"] as? String
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
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            let endDateString = message["end"] as? String
            var endDate:NSDate? = nil
            let startDateString = message["start"] as? String
            var startDate: NSDate? = nil
            
            if let endDateString = endDateString  where endDateString != "" {
                endDate = dateFormatter.dateFromString(endDateString)
                NSNotificationCenter.defaultCenter().postNotificationName("TimerFired", object: ["task":task, "sender":"watch"])
                task.endDate = endDate
                replyHandler(["taskId": task.name, "status": "finished ok"])

            } else  if let startDateString = startDateString {
                startDate = dateFormatter.dateFromString(startDateString)
                NSNotificationCenter.defaultCenter().postNotificationName("TimerStarted", object: ["task":task, "sender":"watch"])
                task.startDate = startDate
                replyHandler(["taskId": task.name, "status": "started ok"])
            }
            saveTasks()
        }
    }
}