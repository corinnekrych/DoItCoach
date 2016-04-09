//
//  InterfaceController.swift
//  DoItCoach WatchKit App Extension
//
//  Created by Corinne Krych on 09/04/16.
//  Copyright © 2016 corinnekrych. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    @IBOutlet var taskNameLabel: WKInterfaceLabel!
    @IBOutlet var group: WKInterfaceGroup!
    @IBOutlet var startButton: WKInterfaceButton!
    @IBOutlet var startButtonImage: WKInterfaceImage!    
    @IBOutlet var timer: WKInterfaceTimer!
    
    @IBAction func onStartButton() {
        guard let currentTask = TasksManager.instance.currentTask else {return} // [1]
        if !currentTask.isStarted() { // [2]
            let duration = NSDate(timeIntervalSinceNow: currentTask.duration)
            timer.setDate(duration)
            // to do timer fired
            NSTimer.scheduledTimerWithTimeInterval(currentTask.duration,
                                                   target: self,
                                                   selector: #selector(NSTimer.fire),
                                                   userInfo: nil,
                                                   repeats: false) // [2]
            timer.start() // [3]
            // to do animate
            group.setBackgroundImageNamed("Time")
            group.startAnimatingWithImagesInRange(NSMakeRange(0, 90), duration: currentTask.duration, repeatCount: 1)
            currentTask.start()

            startButtonImage.setHidden(true) // [4]
            timer.setHidden(false) // [5]
            taskNameLabel.setText(currentTask.name)
        }
    }
    
    func fire() {  // [2]
        timer.stop()
        startButtonImage.setHidden(false)
        timer.setHidden(true)
        guard let current = TasksManager.instance.currentTask else {return}
        current.stop()
        group.stopAnimating()
        display(TasksManager.instance.currentTask)
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        display(TasksManager.instance.currentTask)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func display(task: Task?) {
        guard let task = task else { // [1]
            taskNameLabel.setText("NOTHING TO DO :)")
            timer.setHidden(true)
            startButtonImage.setHidden(true)
            return
        }
        group.setBackgroundImageNamed("Time0")
        taskNameLabel.setText(task.name) // [2]
    }

}
