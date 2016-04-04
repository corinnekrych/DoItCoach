import UIKit

public class DetailledTaskViewController: UIViewController {
    public var task: TaskActivity!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var circleView: CircleView!
    
    @IBAction func startTimer(sender: AnyObject) {
        if task.isStarted() {
            displayError("Already started", viewController: self)
        } else if task.endDate == nil {
            if task.name == TasksManager.instance.currentTask?.name {                
                NSNotificationCenter.defaultCenter().postNotificationName("TimerStarted", object: ["task":task, "sender":"ios"])
            } else {
                displayError("Do your tasks in order :P", viewController: self)
            }
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("timerFired:"), name: "TimerFired", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("timerStarted:"), name: "TimerStarted", object: nil)
        let state = task.endDate != nil ? "done" :(task.startDate == nil ? "toStart" : "isStarted")
        if state == "isStarted" {
            statusLabel.text = "\(task.name)"
            startButton.setTitle("Stop ", forState: .Normal)
            startButton.setTitle("Stop ", forState: .Selected)
            let now = NSDate()
            let spent = now.timeIntervalSinceReferenceDate - (task.startDate?.timeIntervalSinceReferenceDate)!
            circleView.animateCircle(spent, color:task.type.color, duration: task.duration)
        } else if state == "toStart" {
            statusLabel.text = "\(task.name)"
            startButton.setTitle("Start ", forState: .Normal)
            startButton.setTitle("Start ", forState: .Selected)
        } else {
            statusLabel.text = "\(task.name)"
            startButton.setTitle("Done", forState: .Normal)
            startButton.setTitle("Done", forState: .Selected)
            circleView.animateCircle(task.duration, color:task.type.color, duration: task.duration)
        }
    }
    
    @objc public func timerFired(note: NSNotification) {
        if let userInfo = note.object, taskFromNotification = userInfo["task"] as? TaskActivity where taskFromNotification.name == self.task.name {
            saveTasks()
            if let sender = userInfo["sender"] as? String where sender == "watch" {
                print("::Task fired from watch")
            } else {
                print("::Task fired from iOS")
                sendTasksToAppleWatch(self)
            }
            print("iOS app::TimerFired::TaskNotification::\(taskFromNotification)")
            dispatch_async(dispatch_get_main_queue()) {
                self.startButton.setTitle("Done", forState: .Normal)
                self.startButton.setTitle("Done", forState: .Selected)
            }
        }
        print("iOS app::TimerFired::note::\(note)")
    }
    
    @objc public func timerStarted(note: NSNotification) {
        if let userInfo = note.object, let taskFromNotification = userInfo["task"] as? TaskActivity where taskFromNotification.name == self.task.name {
            if let sender = userInfo["sender"] as? String where sender == "ios" {
                task.start()
                sendTaskToAppleWatch(task, viewController: self)
            }
            saveTasks()
            dispatch_async(dispatch_get_main_queue()) {
                self.startButton.setTitle("Stop", forState: .Normal)
                self.startButton.setTitle("Stop", forState: .Selected)
                let now = NSDate()
                let spent = now.timeIntervalSinceReferenceDate - (taskFromNotification.startDate?.timeIntervalSinceReferenceDate)!
                self.circleView.animateCircle(spent, color:taskFromNotification.type.color, duration: taskFromNotification.duration)
            }
        }
        print("iOS app::TimerStarted::note::\(note)")
    }
}


