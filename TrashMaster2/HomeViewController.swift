//
//  ViewController.swift
//  TrashMaster2
//
//  Created by Jocelyn Wang on 7/14/20.
//  Copyright © 2020 Jocelyn Wang. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    @IBAction func LoginGuest(_ sender: UIButton) {
        
        print("Login as Guest")
        self.performSegue(withIdentifier: "DashboardSegue", sender: self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        print("View has loaded")
    }


}



