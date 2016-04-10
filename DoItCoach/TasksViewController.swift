import UIKit

public func displayError(error: String, viewController: UIViewController) {
    let alert = UIAlertController(title: error, message: nil, preferredStyle: .Alert)
    let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
    alert.addAction(okAction)
    viewController.presentViewController(alert, animated: true, completion: nil)
}

class TasksViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var tasksMgr = TasksManager.instance
    
    var newTaskCell: NewTaskCell?
    var addingNewTask: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor.blackColor()
        tableView.separatorStyle = .None
        //loadSavedTasks()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TasksViewController.timerFired(_:)), name: "TimerFired", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
}

// MARK: TaskStarted TaskFired event
extension TasksViewController {
    @objc func timerFired(note: NSNotification) {
        saveTasks()
        self.tableView.reloadData()
    }
}

// MARK: segue
extension TasksViewController {
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let id = segue.identifier where id == "viewTask" {
            if let dest = segue.destinationViewController as? DetailedTaskViewController {
                if let taskCell = sender as? TaskCell, let task = taskCell.task {
                    dest.task = task
                }
            }
        }
    }
}
// MARK: Delete / Move task
extension TasksViewController {
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        if sourceIndexPath.section == 0 {
            guard var remainingTasks = tasksMgr.remainingTasks else {return}
            let moved = remainingTasks[sourceIndexPath.row]
            remainingTasks.removeAtIndex(sourceIndexPath.row)
            remainingTasks.insert(moved, atIndex: destinationIndexPath.row)
            tasksMgr.remainingTasks = remainingTasks
        }
    }
    
    func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            var row = 0
            if sourceIndexPath.section < proposedDestinationIndexPath.section {
                row = self.tableView(tableView, numberOfRowsInSection: sourceIndexPath.section) - 1
            }
            return NSIndexPath(forRow: row, inSection: sourceIndexPath.section)
        }
        return proposedDestinationIndexPath
    }
}

// MARK: Add New Task
extension TasksViewController {
    @IBAction func editMode(sender: UIBarButtonItem) {
        self.tableView.editing = !self.tableView.editing
        saveTasks()
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete && indexPath.section == 0 {
            // Delete the row from the data source
            // meals.removeAtIndex(indexPath.row)
            guard var remainingTasks = tasksMgr.remainingTasks else {return}
            if remainingTasks.count > 0 {
                remainingTasks.removeAtIndex(indexPath.row)
                tasksMgr.remainingTasks = remainingTasks
                if remainingTasks.count == 0 { // always keep on row in section 0
                    tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Fade)
                } else {
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }
            }
            tableView.reloadData()
        }
    }
    
    @IBAction func beginAddingTask() {
        addingNewTask = true
        tableView.allowsSelection = false
        if (tasksMgr.remainingTasks != nil && tasksMgr.remainingTasks?.count > 0) {
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Top)
        } else {
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Bottom)
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(TasksViewController.finishAddingTask))
    }
    
    func finishAddingTask() {
        guard let name = newTaskCell?.taskNameField.text where name.characters.count > 0 else {
            displayError("Name me!", viewController: self)
            return
        }
        
        guard let color = newTaskCell?.selectedColor else {
            displayError("Dont' know that Color????", viewController: self)
            return
        }
        
        let task = TaskActivity(name: name, duration: TaskInterval, type: color, manager: TasksManager.instance)
        tasksMgr.tasks?.insert(task, atIndex: 0)
        addingNewTask = false
        tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Fade)
        newTaskCell?.reset()
        saveTasks()
        tableView.reloadData()
        tableView.endEditing(true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(TasksViewController.beginAddingTask))
        
        tableView.allowsSelection = true
    }
}

// MARK: UITableViewDelegate
extension TasksViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if  (indexPath.section == 1 || tasksMgr.tasks == nil) {
            return
        }
        guard indexPath.section != 1 else { return }
        guard tasksMgr.tasks!.count != 0 else {
            return
        }
        guard !(addingNewTask && indexPath.section == 0 && indexPath.row == 0) else { return }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? NewTaskCell {
            cell.taskNameField.becomeFirstResponder()
        }
    }
}

// MARK: UITableViewDataSource
extension TasksViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if addingNewTask {
                return 1 + (tasksMgr.remainingTasks?.count ?? 0)
            } else {
                return max(1, tasksMgr.remainingTasks?.count ?? 0)
            }
        }
        else if section == 1 {
            if let completed = tasksMgr.completedTasks {
                return completed.count
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.section == 0 && indexPath.row == 0) {
            if addingNewTask {
                let cell = tableView.dequeueReusableCellWithIdentifier("NewTaskCell", forIndexPath: indexPath) as! NewTaskCell
                newTaskCell = cell
                return cell
            }
            else if tasksMgr.remainingTasks == nil || tasksMgr.remainingTasks?.count == 0 {
                // Placeholder when there are no ongoing tasks
                return tableView.dequeueReusableCellWithIdentifier("NoOngoingCell", forIndexPath: indexPath)
            }
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(TaskCell.ReuseId, forIndexPath: indexPath) as! TaskCell
        let task = indexPath.section == 0 ? tasksMgr.remainingTasks![indexPath.row] : tasksMgr.completedTasks![indexPath.row]
        cell.updateWithTask(task)
        
        return cell
    }
    
    // Completed Header
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let completed = tasksMgr.completedTasks {
            if section == 1 && completed.count > 0 {
                return 30
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1 && tasksMgr.tasks!.count > 0 else { return nil }
        let label = UILabel()
        label.text = "COMPLETED"
        label.textAlignment = .Center
        label.textColor = UIColor.whiteColor()
        
        return label
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (addingNewTask && indexPath.row == 0 && indexPath.section == 0) {
            return 90
        }
        return 60
    }
}
