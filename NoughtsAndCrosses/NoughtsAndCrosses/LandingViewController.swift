//
//  LandingViewController.swift
//  OnboardingDemo
//
//  Created by Joe Salter on 5/31/16.
//  Copyright © 2016 Joe Salter. All rights reserved.
//

import UIKit

class LandingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title  = "Auth Menu"
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func loginButtonTapped(sender: UIButton) {
        let lvc = LoginViewController()
        self.navigationController?.pushViewController(lvc, animated: true)
    }
    
    @IBAction func registerButtonTapped(sender: UIButton) {
        let rvc = RegisterViewController()
        self.navigationController?.pushViewController(rvc, animated: true)
    }
}
