//
//  ToDoItem.swift
//  IoTiOSToDoList
//
//  Created by Zachary Donato on 11/29/16.
//  Copyright © 2016 CS810IoT. All rights reserved.
//

import UIKit

class ToDoItem: NSObject {

    // Text description of the item.
    var text: String
    // Bool val for whether item is completed or not.
    var completed: Bool
    
    
    init(text: String) {
        self.text = text
        self.completed = false
    }
    
}
