import Foundation

public let TaskInterval = NSTimeInterval(10)
public let WorkoutInterval = NSTimeInterval(5)
public let LongWorkoutInterval = NSTimeInterval(5)
import UIKit

public enum TaskType: Int, CustomStringConvertible {
    case Task = 0, Break = 1, LongBreak = 2
    public static let allColors = [Task, Break, LongBreak]
    
    public var name: String {
        switch self {
        case .Task:     return "Task"
        case .Break:   return "Break"
        case .LongBreak:    return "LongBreak"
        }
    }
    
    public var color: UIColor {
        switch self {
        case .Task:    return UIColor(red: 32/255.0, green: 148/255.0, blue: 250/255.0, alpha: 1)
        case .Break:   return UIColor(red: 255/255.0, green: 149/255.0, blue: 0/255.0, alpha: 1)
        case .LongBreak:   return UIColor(red: 255/255.0, green: 59/255.0, blue: 48/255.0, alpha: 1)
        }
    }
    
    public var description: String {
        return name
    }
    
    public init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .Task
        case 1: self = .Break
        case 2: self = .LongBreak
        default: return nil
        }
    }
}

public protocol Task: CustomStringConvertible {
    var name: String {get}
    var duration: NSTimeInterval {get}
    var tasksManager: TasksManager {get}
    var startDate: NSDate? {get set}
    var endDate: NSDate? {get set}
    var timer: NSTimer? {get set}
    var remainingTime: NSTimeInterval? {get}
    var type: TaskType {get set}
    func start()
    func stop()
    func isStarted() -> Bool
    init(name: String, duration: NSTimeInterval, startDate: NSDate?, endDate: NSDate?, type: TaskType, manager: TasksManager)
}

final public class TaskActivity: NSObject, Task {
    public let name: String
    public let duration: NSTimeInterval
    public let tasksManager: TasksManager
    public var startDate: NSDate?
    public var endDate: NSDate?
    public var timer: NSTimer?
    public var type: TaskType
    
    
    public override var description: String {
        return "\(self.name)"
    }
    
    public var remainingTime: NSTimeInterval? {
        get {
            return timer?.fireDate.timeIntervalSinceNow
        }
    }
    
    public required init(name: String, duration: NSTimeInterval, startDate: NSDate? = nil, endDate: NSDate? = nil, type: TaskType = .Task, manager: TasksManager) {
        self.name = name
        self.duration = duration
        self.type = type
        tasksManager = manager
        self.startDate = startDate
        self.endDate = endDate
    }
    
    public convenience init(name: String, manager: TasksManager) {
        self.init(name: name, duration: NSTimeInterval(TaskInterval), startDate:nil, endDate: nil,  manager: manager)
    }
    
    public func start() {
        startDate = NSDate()
        timer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: Selector("stop"), userInfo: nil, repeats: false)
    }
    
    public func stop() {
        print("fire")
        endDate = NSDate()
        timer?.invalidate()
        NSNotificationCenter.defaultCenter().postNotificationName("TimerFired", object: ["task":self])
    }
    
    public func isStarted() -> Bool {
        return timer?.valid ?? false
    }
    
    public func toDictionary() -> [String: AnyObject] {
        var dict: [String: AnyObject] = [:]
        dict["name"] = name
        dict["duration"] = duration
        dict["type"] = type.rawValue
        if let startDate = startDate {
            dict["startDate"] = startDate.timeIntervalSinceReferenceDate
        }
        if let endDate = endDate {
            dict["endDate"] = endDate.timeIntervalSinceReferenceDate
        }
        return dict
    }

}

// MARK: NSCoding
extension TaskActivity: NSCoding {

    public convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObjectForKey("name") as? String,
            let duration = aDecoder.decodeObjectForKey("duration") as? NSTimeInterval,
            let intType = aDecoder.decodeObjectForKey("type") as? Int, let type = TaskType(rawValue:intType)
            else {return nil}
        let date1 = aDecoder.decodeObjectForKey("startDate") as?  NSDate
        let date2 = aDecoder.decodeObjectForKey("endDate") as? NSDate
        self.init(name: name, duration: duration, startDate: date1, endDate:  date2, type: type, manager: TasksManager.instance)
    }
    
    public func encodeWithCoder(encoder: NSCoder) {
        encoder.encodeObject(name, forKey: "name")
        encoder.encodeObject(duration, forKey: "duration")
        encoder.encodeObject(type.rawValue, forKey: "type")
        if let startDate = startDate {
            encoder.encodeObject(startDate, forKey: "startDate")
        }
        if let endDate = endDate {
            encoder.encodeObject(endDate, forKey: "endDate")
        }
    }}