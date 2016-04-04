//
//  InterfaceController.swift
//  Pom WatchKit Extension
//
//  Created by Corinne Krych on 26/02/16.
//  Copyright © 2016 corinne. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController {
    
    @IBOutlet var taskNameLabel: WKInterfaceLabel!
    @IBOutlet var group: WKInterfaceGroup!
    @IBOutlet var startButton: WKInterfaceButton!
    @IBOutlet var timer: WKInterfaceTimer!
    @IBOutlet var startButtonImage: WKInterfaceImage!

    var timerFire: NSTimer!
    var session: WCSession!
    var tasksMgr: TasksManager!
    
    override func willActivate() {
        super.willActivate()
        
        guard let currentTask = tasksMgr.currentTask else {return}
        display(currentTask)
        if let _ = currentTask.startDate where currentTask.endDate == nil {
            replayAnimation(currentTask)
        }
    }
    
    func tasksUpdated(note: NSNotification) { // insert new task, or task completed on ios app
        group.setBackgroundImageNamed("Time0")
        self.display(tasksMgr.currentTask)
    }
    
    func taskStarted(note: NSNotification) { // task started from ios app
        print("Task started from iOS")
        if let userInfo = note.object, let taskFromNotification = userInfo["task"] as? TaskActivity, let current = tasksMgr.currentTask where taskFromNotification.name == current.name {
            print("Task started from iOS::Replay animation")
            replayAnimation(taskFromNotification)
        }
    }
    
    func replayAnimation(task: TaskActivity) {
        if let startDate = task.startDate  {
            print("Task started from iOS::inside Replay animation")
            dispatch_async(dispatch_get_main_queue()) {
                self.group.setBackgroundImageNamed("Time")
                let timeElapsed = NSDate().timeIntervalSinceDate(startDate) // issue with clock diff, this interval might be negative
                let diff = timeElapsed < 0 ? abs(timeElapsed) : timeElapsed
                let imageRangeRemaining = (diff)*90/task.duration
                self.group.startAnimatingWithImagesInRange(NSMakeRange(Int(imageRangeRemaining), 90), duration: task.duration - diff, repeatCount: 1)
                let rim = Int(imageRangeRemaining)
                print("::RIM \(rim):: elapsed \(diff) task.duration \(task.duration)")
                self.display(task)
            }
        }
    }

    override func awakeWithContext(context: AnyObject?) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("tasksUpdated:"), name: "TasksUpdated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("taskStarted:"), name: "CurrentTaskStarted", object: nil)

        super.awakeWithContext(context)
        group.setBackgroundImageNamed("Time")
        
        let delegate = WKExtension.sharedExtension().delegate as! ExtensionDelegate
        session = delegate.session
        tasksMgr = delegate.tasksMgr
        display(tasksMgr.currentTask)
    }
    
    override func didAppear() {
        super.didAppear()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    @IBAction func stop() {
        guard let currentTask = tasksMgr.currentTask else {return}
        timer.stop()
        timerFire.invalidate()
        startButtonImage.setHidden(false)
        timer.setHidden(true)
        currentTask.stop()
        group.stopAnimating()
        // init for next task
        group.setBackgroundImageNamed("Time0")
        display(tasksMgr.currentTask)
    }
    
    @IBAction func onStartButton() {
        print("onStartButton")
        guard let currentTask = tasksMgr.currentTask else {return}
        if !currentTask.isStarted() {
            print("currentActivitied:\(currentTask.name):")
            let duration = NSDate(timeIntervalSinceNow: currentTask.duration)
            timer.setDate(duration)
            timer.start()
            timerFire = NSTimer.scheduledTimerWithTimeInterval(currentTask.duration, target: self, selector: "fire", userInfo: nil, repeats: false)
            currentTask.start()
            group.setBackgroundImageNamed("Time")
            group.startAnimatingWithImagesInRange(NSMakeRange(0, 90), duration: currentTask.duration, repeatCount: 1)
            startButtonImage.setHidden(true)
            timer.setHidden(false)
            sendStartTimer(currentTask.name, startDate: currentTask.startDate, endDate: currentTask.endDate)
        }
    }
    
    func sendStartTimer(taskName: String, startDate: NSDate?, endDate: NSDate?) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var startDateString: String
        if let startDate = startDate {
            startDateString = dateFormatter.stringFromDate(startDate)
        } else {
            startDateString = ""
        }
        var endDateString: String
        if let endDate = endDate {
            endDateString = dateFormatter.stringFromDate(endDate)
        } else {
            endDateString = ""
        }
        let applicationData = ["task": taskName, "start": startDateString, "end": endDateString]
        print("SEND from watch \(applicationData)")
        if session.reachable {
            session.sendMessage(applicationData, replyHandler: {(dict: [String : AnyObject]) -> Void in
                // handle reply from iPhone app here
                print("iOS APP KNOWS Watch \(dict)")
                }, errorHandler: {(error) -> Void in
                    // catch any errors here
                    print("OOPs... Watch \(error)")
            })
        } else {
            alertiOSAppLocked()
            print("SESSION REACHable\(session.reachable)")
        }
    }
    
    func alertiOSAppLocked() {
        let action = WKAlertAction(title: "Ok", style: .Default) {}
        presentAlertControllerWithTitle("PomCoach", message: "Looks like your phone is locked. Unlock!", preferredStyle: .ActionSheet, actions: [action])
    }
    
    func fire() {
        timer.stop()
        startButtonImage.setHidden(false)
        timer.setHidden(true)
        guard let current = tasksMgr.currentTask else {return}
        print("FIRE: \(current.name)")
        current.stop()
        group.stopAnimating()
        // init for next
        group.setBackgroundImageNamed("Time0")
        display(tasksMgr.currentTask)
        sendStartTimer(current.name, startDate: current.startDate, endDate: current.endDate)
    }
    
    func display(task: Task?) {
        guard let task = task else {
            taskNameLabel.setText("NOTHING TO DO :)")
            timer.setHidden(true)
            startButtonImage.setHidden(true)
            return
        }
        startButtonImage.setHidden(false)
        taskNameLabel.setText(task.name)
    }
}