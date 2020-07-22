//
//  ViewController.swift
//  TrashMaster2
//
//  Created by Jocelyn Wang on 7/14/20.
//  Copyright © 2020 Jocelyn Wang. All rights reserved.
//

import UIKit
import GoogleMaps
import MessageUI

class DashboardViewController: UIViewController {

    @IBAction func goToMap(_ sender: UIButton) {
        print("Go to Map Kit")
        self.performSegue(withIdentifier: "MapKitSegue", sender: self)
    }
    
    @IBAction func goToReportMap(_ sender: UIButton) {
        print("Go to Report Map")
        self.performSegue(withIdentifier: "ReportTrashSegue", sender: self)
    }
    
    @IBAction func issueButtonTapped(_ sender: UIButton) {
        // This needs to be ran on a device
        showMailComposer()
    }
    
    func showMailComposer() {
        guard MFMailComposeViewController.canSendMail() else {
            // show alert informing the user
            print("Can't send mail")
            showMailError()
            return
        }
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self as! MFMailComposeViewControllerDelegate
        composer.setToRecipients(["support@trashmaster.com"])
        composer.setSubject("Report Issue with Trash Master App")
        composer.setMessageBody("Issue: ", isHTML: false)
        
        present(composer, animated: true)
    }
    
    func showMailError() {
        let sendMailErrorAlert = UIAlertController(title: "Could not send email", message: "Your device could not send email", preferredStyle: .alert)
        let dismiss = UIAlertAction(title: "Okay", style: .default, handler: nil)
        sendMailErrorAlert.addAction(dismiss)
        self.present(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension DashboardViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let _ = error {
            // show error alert
            controller.dismiss(animated: true)
        }
        
        switch result {
        case .cancelled:
            print("Cancelled")
        case .failed:
            print("Failed to Send")
        case .saved:
            print("Saved")
        case .sent:
            print("Email Sent")
        }
        
        controller.dismiss(animated: true)
    }
}

