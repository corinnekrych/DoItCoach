//
//  GlanceController.swift
//  Pom WatchKit Extension
//
//  Created by Corinne Krych on 26/02/16.
//  Copyright © 2016 corinne. All rights reserved.
//

import WatchKit
import Foundation


class GlanceController: WKInterfaceController {

    @IBOutlet var taskName: WKInterfaceLabel!
    @IBOutlet var group: WKInterfaceGroup!
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if let current = TasksManager.instance.currentTask {
            taskName.setText(current.name)
            if let startDate = current.startDate {
            self.group.setBackgroundImageNamed("Time")
            let timeElapsed = NSDate().timeIntervalSinceDate(startDate)
            let diff = timeElapsed < 0 ? abs(timeElapsed) : timeElapsed
            let imageRangeRemaining = (diff)*90/current.duration
            self.group.startAnimatingWithImagesInRange(NSMakeRange(Int(imageRangeRemaining), 90), duration: current.duration - diff, repeatCount: 1)
            }

        } else {
            taskName.setText("Nothing to do :)")
            self.group.setBackgroundImageNamed("Time0")
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
