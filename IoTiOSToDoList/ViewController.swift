//
//  ViewController.swift
//  IoTiOSToDoList
//
//  Created by Zachary Donato on 11/29/16.
//  Copyright © 2016 CS810IoT. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TableViewCellDelegate, UIScrollViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var toDoItems = [CKRecord]()
    
    // Show a loading indicator.
    private let loading = UIAlertView(title: "", message: "Loading To Do Items...", delegate: nil, cancelButtonTitle: nil)
    
    // MARK: - View Did Load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        loading.show()
        
        fetchToDoItems()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "cell")
        
        // Some styles
        tableView.backgroundColor = UIColor.black
        tableView.rowHeight = 50.0
        
    }
    
    // MARK: - Fetch all ToDoItems
    func fetchToDoItems() {
        self.toDoItems.removeAll()
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
                
                self.loading.message = "Finished!"
                self.loading.dismiss(withClickedButtonIndex: -1, animated: true)
                
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
    
    // MARK: - Save To Do Item
    func saveToDoItem(toDoItem: CKRecord) {
        let container = CKContainer.default()
        let db = container.publicCloudDatabase
        
        db.save(toDoItem) { (savedToDoItem, error) in
            if (error != nil) {
                print(error)
            } else {
                print(savedToDoItem)
            }
        }
    }
    
    // MARK: - Add To Do Item
    func addToDoItem() {
        // Create the alert controller.
        let alert = UIAlertController(title: "Add To Do Item", message: "", preferredStyle: .alert)
        
        // Add the text field.
        alert.addTextField { (textField) in }
        
        // Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            print("Text field: \(textField?.text)")
            
            let toDoItemString = textField?.text
            
            let newToDoRecord = CKRecord(recordType: "ToDoItem")
            newToDoRecord.setValue(toDoItemString, forKey: "string")
            newToDoRecord.setValue("false", forKey: "completed")
            
            OperationQueue.main.addOperation {
                // Add the new record to our tableview.
                self.toDoItems.insert(newToDoRecord, at: 0)
                self.tableView.reloadData()
            }
            
            self.saveToDoItem(toDoItem: newToDoRecord)
            }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }

    
    // MARK: - TableViewCellDelegate - Complete Item
    func todoItemCompleted(todoItem: CKRecord) {
        // Mark item as completed.
        todoItem.setValue("true", forKey: "completed")
        
        print(todoItem.value(forKey: "completed"))
        saveToDoItem(toDoItem: todoItem)
        
        OperationQueue.main.addOperation { 
            self.tableView.reloadData()
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    // placeholder cell for adding item
    let placeHolderCell = TableViewCell(style: .default, reuseIdentifier: "cell")
    var pullDownInProgress = false
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pullDownInProgress = scrollView.contentOffset.y <= 0.0
        placeHolderCell.backgroundColor = UIColor.red
        
        if pullDownInProgress {
            tableView.insertSubview(placeHolderCell, at: 0)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollViewContentOffsetY = scrollView.contentOffset.y
        
        if pullDownInProgress && scrollView.contentOffset.y <= 0.0 {
            placeHolderCell.frame = CGRect(x: 0, y: -tableView.rowHeight, width: tableView.frame.size.width, height: tableView.rowHeight)
            placeHolderCell.textLabel?.text = -scrollViewContentOffsetY > tableView.rowHeight ? "Release to add item" : "Pull to add item"
            
            placeHolderCell.alpha = min(1.0, -scrollViewContentOffsetY / tableView.rowHeight)
        } else {
            pullDownInProgress = false
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // check whether the user pulled down far enough
        if pullDownInProgress && -scrollView.contentOffset.y > tableView.rowHeight {
            addToDoItem()
        }
        
        pullDownInProgress = false
        placeHolderCell.removeFromSuperview()
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
        
        if (item.value(forKey: "completed") as? String == "true") {
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: (item.value(forKey: "string") as? String)!)
            attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))
            cell.textLabel?.attributedText = attributeString;
        } else {
            cell.textLabel?.text = item.value(forKey: "string") as? String
        }
        
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
    
    @IBAction func refresh(_ sender: AnyObject) {
        fetchToDoItems()
    }
}

