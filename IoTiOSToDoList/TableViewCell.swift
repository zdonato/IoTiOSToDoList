//
//  TableViewCell.swift
//  IoTiOSToDoList
//
//  Created by Zachary Donato on 12/1/16.
//  Copyright © 2016 CS810IoT. All rights reserved.
//

import UIKit

// A protocol that the TableViewCell uses to inform its delegate of state change
protocol TableViewCellDelegate {
    // indicates that the given item has been deleted
    func todoItemDeleted(todoItem: ToDoItem)
}

class TableViewCell: UITableViewCell {
    
    var originalCenter = CGPoint()
    var deleteOnDragRelease = false
    var delegate: TableViewCellDelegate?
    
    // The item that this cell renders
    var toDoItem: ToDoItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // add the pan recognizer
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(TableViewCell.handlePan))
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Horizontal Pan Gesture Methods
    func handlePan(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            originalCenter = center
        }
        
        if recognizer.state == .changed {
            let translation = recognizer.translation(in: self)
            center = CGPoint(x: originalCenter.x + translation.x, y: originalCenter.y)
            
            // Check if user has dragged far enough to delete the item
            deleteOnDragRelease = frame.origin.x < -frame.size.width / 2.0
        }
        
        if recognizer.state == .ended {
            // The frame the cell had before the user dragged it.
            let originalFrame = CGRect(x: 0, y: frame.origin.y, width: bounds.size.width, height: bounds.size.height)
            
            if !deleteOnDragRelease {
                // If the item is not being deleted, snap back to the original location.
                UIView.animate(withDuration: 0.2, animations: {self.frame = originalFrame})
            } else {
                if delegate != nil && toDoItem != nil {
                    delegate!.todoItemDeleted(todoItem: toDoItem!)
                }
            }
        }
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: superview!)
            if fabs(translation.x) > fabs(translation.y) {
                return true
            }
            
            return false
        }
        
        return false;
    }
}
