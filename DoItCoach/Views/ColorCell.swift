//
//  ColorCell.swift
//  Pom
//
//  Created by Corinne Krych on 27/02/16.
//  Copyright © 2016 corinne. All rights reserved.
//
import UIKit

class ColorCell: UICollectionViewCell {
  static let ReuseId = "ColorCell"
  @IBOutlet weak var selectionView: UIView!
  
  override func awakeFromNib() {
    selectionView.layer.borderColor = UIColor.whiteColor().CGColor
    selectionView.layer.borderWidth = 4
  }
  
  func setColor(color: UIColor) {
    backgroundColor = color
  }
  
  override var selected: Bool {
    didSet {
      selectionView.hidden = !selected
    }
  }
}
