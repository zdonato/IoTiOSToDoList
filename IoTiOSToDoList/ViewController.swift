//
//  ViewController.swift
//  IoTiOSToDoList
//
//  Created by Zachary Donato on 11/29/16.
//  Copyright © 2016 CS810IoT. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TableViewCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var toDoItems = [CKRecord]()
    
    // MARK: - View Did Load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        fetchToDoItems()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "cell")
        
        // Some styles
        tableView.backgroundColor = UIColor.black
        tableView.rowHeight = 50.0
        
//        toDoItems.append(ToDoItem(text: "feed the cat"))
//        toDoItems.append(ToDoItem(text: "buy eggs"))
//        toDoItems.append(ToDoItem(text: "watch WWDC videos"))
//        toDoItems.append(ToDoItem(text: "rule the Web"))
//        toDoItems.append(ToDoItem(text: "buy a new iPhone"))
//        toDoItems.append(ToDoItem(text: "darn holes in socks"))
//        toDoItems.append(ToDoItem(text: "master Swift"))
//        toDoItems.append(ToDoItem(text: "learn to draw"))
//        toDoItems.append(ToDoItem(text: "get more exercise"))
//        toDoItems.append(ToDoItem(text: "catch up with Mom"))
//        toDoItems.append(ToDoItem(text: "get a hair cut"))
    }
    
    // MARK: - Fetch all ToDoItems
    func fetchToDoItems() {
        let container = CKContainer.default()
        let db = container.publicCloudDatabase
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "ToDoItem", predicate: predicate)
        
        db.perform(query, inZoneWith: nil) { (results, error) in
            if error != nil {
                print(error)
            } else {
                print(results)
                
                for result in results! {
                    self.toDoItems.append(result)
                    
                    print(result.object(forKey: "string")!)
                }
                
                print(self.toDoItems)
                
                OperationQueue.main.addOperation({ 
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    // MARK: - TableViewCellDelegate - Delete Item
    func todoItemDeleted(todoItem: CKRecord) {
        let index = (toDoItems as NSArray).index(of: todoItem)
        
        if index == NSNotFound { return }
        
        toDoItems.remove(at: index)
        
        // Delete from iCloud
        let id = todoItem.recordID
        
        let container = CKContainer.default()
        let db = container.publicCloudDatabase
        
        db.delete(withRecordID: id) { (deletedRecordID, error) in
            if error != nil {
                print(error)
            } else {
                OperationQueue.main.addOperation({
                    self.tableView.beginUpdates()
                    let indexPathForRow = NSIndexPath(item: index, section: 0)
                    self.tableView.deleteRows(at: [indexPathForRow as IndexPath], with: .fade)
                    self.tableView.endUpdates()
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    // MARK: - Table View Data Source
    @nonobjc func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath) as! TableViewCell
        
        let item: CKRecord = toDoItems[indexPath.row]
        
        
        cell.textLabel?.text = item.value(forKey: "string") as? String
        cell.delegate = self
        cell.toDoItem = item
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.rowHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.backgroundColor = UIColor.white
        cell.textLabel?.textColor = UIColor.black
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    @IBAction func addToDoItem(_ sender: AnyObject) {
        
    }
}

