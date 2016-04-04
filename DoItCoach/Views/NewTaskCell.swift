//
//  NewTaskCell.swift
//  Pom
//
//  Created by Corinne Krych on 27/02/16.
//  Copyright © 2016 corinne. All rights reserved.
//
import UIKit

class NewTaskCell: UITableViewCell {
  
  @IBOutlet weak var topContainer: UIView!
  @IBOutlet weak var taskNameField: UITextField!
  
  @IBOutlet var colorButtons: [UIButton]!
  
  var selectedColor: TaskType!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    for (i, button) in colorButtons.enumerate() {
      guard let color = TaskType(rawValue: i)?.color else { continue }
      button.backgroundColor = color
    }
    reset()
  }
  
  func reset() {
    selectedColor = TaskType.Task
    topContainer.backgroundColor = selectedColor.color
    taskNameField.text = nil
  }
  
  @IBAction func onColorButton(sender: UIButton) {
    guard let index = colorButtons.indexOf(sender) else { return }
    guard let color = TaskType(rawValue: index) else { return }
    
    selectedColor = color
    
    topContainer.backgroundColor = selectedColor.color
  }
}
