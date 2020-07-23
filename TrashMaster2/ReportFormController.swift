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
    @IBOutlet weak var trashImageView: UIImageView!
    
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
    
    // TODO - currently not being used, may consider deleting
    func addTrashLocationData() {
        ref?.child("trash-location").childByAutoId().setValue(data)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func enterTapped(_ sender: Any) {
        data["description"] = descriptionField.text
        data["date"] = formatter.string(from: date)
        print(data["trashPhotoURL"])
    
        ref?.child("trash-location").childByAutoId().setValue(data)
        
        print("Go to Report Map after adding data")
        self.performSegue(withIdentifier: "ReportFormtoMapSegue", sender: self)
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        print("Go to Report Map without adding data")
        self.performSegue(withIdentifier: "ReportFormtoMapSegue", sender: self)
    }
    
    @IBAction func uploadPhoto(_ sender: UIButton) {
        selectImage()
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

extension ReportFormController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @objc func selectImage() {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    
    // https://stackoverflow.com/questions/53200311/image-not-show-in-uiimageview
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImageFromPicker: UIImage?
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }

        if let selectedImage = selectedImageFromPicker {
            trashImageView.image = selectedImage
        }
        print(trashImageView.image)
        print(selectedImageFromPicker)

        dismiss(animated: true, completion: nil)
        
        return saveImageToDatabase()
    }
    
    func saveImageToDatabase() {
        let imageName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("\(imageName).png")
        
        if let uploadData = self.trashImageView.image!.pngData() {
            storageRef.putData(uploadData, metadata: nil, completion: {
                (metadata, error) in
                if error != nil {
                    print(error)
                    return
                }
                
               // https://stackoverflow.com/questions/52611994/swift-firebase-metadata-downloadurl-absolutestring
               storageRef.downloadURL(completion: {(url, error) in
                   if error != nil {
                       print(error!.localizedDescription)
                       return
                   }
                   
                   let downloadURL = url?.absoluteString
                   self.data["trashImageURL"] = downloadURL
               })
            })
        }
    }
    
    private func uploadPhotoIntoDatabaseWithUID(uid: String, values: [String: AnyObject]) {
        let ref = Database.database().reference(fromURL: "https://trash-master-b5f78.firebaseio.com/")
        let trashReference = ref.child("trash-location").child(uid)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled picker")
        dismiss(animated: true, completion: nil)
    }
}
