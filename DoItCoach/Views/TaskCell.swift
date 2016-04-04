//
//  TaskCell.swift
//  Pom
//
//  Created by Corinne Krych on 27/02/16.
//  Copyright © 2016 corinne. All rights reserved.
//
import UIKit

public class TaskCell: UITableViewCell {
  static let ReuseId = "TaskCell"
  
  @IBOutlet weak var nameLabel: UILabel!
  public var task: TaskActivity!
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    selectionStyle = .None
  }
}

// MARK: Populate Cell
extension TaskCell {
    func updateWithTask(task: TaskActivity, postfix: String = "") {
        self.task = task
        nameLabel.text = "\(task.name) \(postfix)"
        self.backgroundColor = task.type.color
    }
}