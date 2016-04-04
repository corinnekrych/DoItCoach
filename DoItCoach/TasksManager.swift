import Foundation

public func saveTasks() {
    print("Saving...")
    if let tasks = TasksManager.instance.tasks {
        let object = NSKeyedArchiver.archivedDataWithRootObject(tasks)
        NSUserDefaults.standardUserDefaults().setObject(object, forKey: "objects")
        NSUserDefaults.standardUserDefaults().synchronize()
        print("Saved...")
    }
}

public func loadSavedTasks() {
    if let savedObjects = NSUserDefaults.standardUserDefaults().objectForKey("objects") as? NSData {
        let act = NSKeyedUnarchiver.unarchiveObjectWithData(savedObjects) as! [TaskActivity]
        act.map({ (task: TaskActivity) -> TaskActivity in
            print("act::\(task.name)::\(task.startDate)::\(task.endDate)::\(task.duration)::\(task.type)")
            return task
        })
        TasksManager.instance.tasks = act
    }
}

final public class TasksManager {
    public var tasks: [TaskActivity]? = []
    public static let instance = TasksManager()
    
    public init() {
    }
    
    public init(tasks: [TaskActivity]) {
        self.tasks = tasks
    }
    
    public var remainingTasks:[TaskActivity]? {
        get {
            return tasks?.filter {$0.endDate == nil}
        }
        set {
            if let newValue = newValue {
                if let completedTasks = completedTasks {
                    tasks = newValue + completedTasks
                } else {
                    tasks = newValue
                }
            } else {
                tasks = completedTasks
            }
            
        }
    }
    
    public var currentTask:TaskActivity? {
        get {
            guard let tasks = remainingTasks else {return nil}
            if tasks.count == 0 {return nil}
            return tasks[0]
        }
    }
    
    public var completedTasks:[TaskActivity]? {
        get {
            return tasks?.filter {$0.endDate != nil}
        }
    }
}
