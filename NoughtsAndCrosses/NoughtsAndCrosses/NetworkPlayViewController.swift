//
//  NetworkPlayViewController.swift
//  NoughtsAndCrosses
//
//  Created by Joe Salter on 6/3/16.
//  Copyright © 2016 Julian Hulme. All rights reserved.
//

import UIKit

class NetworkPlayViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var gameList: [OXGame]?
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.translucent = false

        // Do any additional setup after loading the view.
        self.navigationController?.navigationBarHidden = false
        self.title = "Network Play"
        
        tableView.dataSource = self
        tableView.delegate = self
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Release to refresh")
        refreshControl.addTarget(self, action: #selector(NetworkPlayViewController.refreshTable), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
    }
    
    func refreshTable() {
        //OXGameController.sharedInstance.gameList(self, viewControllerCompletionFunction: {(gameList, message) in self.gameListReceived(gameList, message: message)  })
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    override func viewDidAppear(animated: Bool) {
        OXGameController.sharedInstance.gameList(self, viewControllerCompletionFunction: {(gameList, message) in self.gameListReceived(gameList, message: message)  })
    }
    
    func gameListReceived(games:[OXGame]?,message:String?) {
        print("games received \(games)")
        
        if let newGames = games {
            self.gameList = newGames
        }
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
        
        //self.gamesList = OXGameController.sharedInstance.getListOfGames()!
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("did select row \(indexPath.row)")
        
        OXGameController.sharedInstance.acceptGame(self.gameList![indexPath.row].gameId!, presentingViewController: self, viewControllerCompletionFunction: {(game, message) in self.acceptGameComplete(game, message:message)})
        
        
    }
    
    func acceptGameComplete(game: OXGame?, message: String?) {
        print("accept game call complete")
        
        if let gameAcceptedSuccess = game {
            let networkBoardView = BoardViewController(nibName: "BoardViewController", bundle: nil)
            networkBoardView.networkGame = true
            networkBoardView.currentGame = gameAcceptedSuccess
            self.navigationController?.pushViewController(networkBoardView, animated: true)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if gameList != nil {
            return gameList!.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "ID: " + String(gameList![indexPath.item].gameId!) + " - " + String(gameList![indexPath.item].hostUser!.email)
        
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Available Online Games"
    }
    
    @IBAction func startNewNetworkGameTapped(sender: UIButton) {
        OXGameController.sharedInstance.createNewGame(UserController.sharedInstance.getLoggedInUser()!, presentingViewController: self, viewControllerCompletionFunction: {(game, message) in self.newGameComplete(game, message:message)})
    
        //let bvc = BoardViewController()
        //BoardViewController.networkGame = true
        //self.navigationController?.pushViewController(bvc, animated: true)
    }
    
    func newGameComplete(game: OXGame?, message: String?) {
        print("new game call complete")
        
        
        if let newGameSuccess = game {
            let networkBoardView = BoardViewController(nibName: "BoardViewController", bundle: nil)
            networkBoardView.networkGame = true
            networkBoardView.currentGame = newGameSuccess
            self.navigationController?.pushViewController(networkBoardView, animated: true)
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
