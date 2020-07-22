//
//  ReportFormController.swift
//  TrashMaster2
//
//  Created by Jocelyn Wang on 7/21/20.
//  Copyright © 2020 Jocelyn Wang. All rights reserved.
//

import UIKit
import Firebase

class ReportFormController: UIViewController {
    
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var textView: UITextView!

    var ref:DatabaseReference?
    var databaseHandle:DatabaseHandle?
    var postData = [Dictionary<String, Any>]()
    
    var data = [String: Any]()
    var address = ""
    
    let date = Date()
    let formatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        formatter.dateFormat = "yyyy-MM-dd"
        
        descriptionField.delegate = self
        textView.text = "Location: \(address) \nReport Date: \(formatter.string(from: date)) \nReport Type: Trash"
        print("Report Form has loaded")
    }
    
    func addTrashLocationData() {
        ref?.child("trash-location").childByAutoId().setValue(data)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func enterTapped(_ sender: Any) {
        data["description"] = descriptionField.text
        data["date"] = formatter.string(from: date)
        
    ref?.child("trash-location").childByAutoId().setValue(data)
        
        print("Go to Report Map after adding data")
        self.performSegue(withIdentifier: "ReportFormtoMapSegue", sender: self)
    }
    
    
    @IBAction func cancelTapped(_ sender: Any) {
        print("Go to Report Map without adding data")
        self.performSegue(withIdentifier: "ReportFormtoMapSegue", sender: self)
    }
    
    
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        descriptionField.resignFirstResponder()
    }
    
}

extension ReportFormController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
