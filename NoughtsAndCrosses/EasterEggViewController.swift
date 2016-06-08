//
//  EasterEggViewController.swift
//  NoughtsAndCrosses
//
//  Created by Joe Salter on 6/1/16.
//  Copyright © 2016 Julian Hulme. All rights reserved.
//

import UIKit

class EasterEggViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // "Return to game" button tapped, bring user back to game
    @IBAction func returnToGameTapped(sender: UIButton) {
        let bvc = BoardViewController()
        self.navigationController?.pushViewController(bvc, animated: true)
    }
}
