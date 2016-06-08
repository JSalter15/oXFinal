//
//  OXGameController.swift
//  NoughtsAndCrosses
//
//  Created by Alejandro Castillejo on 6/2/16.
//  Copyright © 2016 Julian Hulme. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON


enum CellType : String {
    
    case O = "O"
    case X = "X"
    case EMPTY = ""
    
}

enum OXGameState : String {
    
    case inProgress
    case complete_no_one_won
    case complete_someone_won
    case open
    case abandoned
    
}

class OXGame    {
    
    //the board data, stored in a 1D array
    
    var board = [CellType](count: 9, repeatedValue: CellType.EMPTY)
    //the type of O or X that plays first
    private var startType:CellType = CellType.X
    
    var gameId: String?
    var hostUser: User?
    var guestUser: User?
    var backendState: OXGameState?
    
    //default constructor
    init()  {
        
    }
    
    //constructor from JSON
    init(json:JSON)  {
        print("json init")
        self.gameId = json["id"].stringValue
        self.backendState = OXGameState(rawValue: json["state"].stringValue)
        self.board = deserialiseBoard(json["board"].stringValue)
        self.hostUser = User(json:json["host_user"])
        self.guestUser = User(json:json["guest_user"])
        
    }
    
    private func deserialiseBoard(boardString:String) -> [CellType] {
        
        var newBoard:[CellType] = []
        for (index, char) in boardString.characters.enumerate() {
            print (char)
            
            if (char == "_")   {
                //EMPTY
                newBoard.append(CellType.EMPTY)
            }   else if (char == "x")  {
                newBoard.append(CellType.X)
            }   else if (char == "o")  {
                newBoard.append(CellType.O)
            }
        }
        return newBoard
    }
    
    func serialiseBoard() -> String  {
        
        var resultBoard = ""
        for cell in self.board  {
            if (cell == CellType.EMPTY) {
                resultBoard = resultBoard + "_"
            }   else if (cell == CellType.O)  {
                resultBoard = resultBoard + "o"
            }   else    {
                resultBoard = resultBoard + "x"
            }
        }
        
        return resultBoard
    }
    
    
    //returns the number of turns the players have had on the board
    private func turn() -> Int {
        return board.filter{(pos) in (pos != CellType.EMPTY)}.count
    }
    
    //returns if its X or O's turn to play
    func whosTurn()  -> CellType {
        let count = turn()
        if (count % 2 == 0)   {
            return startType
        }   else    {
            
            if (startType == CellType.X)    {
                return CellType.O
            }   else    {
                return CellType.X
            }
        }
        
    }
    
    func whoJustPlayed()   -> CellType {
        let next = whosTurn()
        if (next == CellType.X)   {
            return CellType.O
        }   else    {
            return CellType.X
        }
    }
    
    func localUsersTurn() -> Bool  {
        
        let XorO = whosTurn()
        if (self.hostUser?.email == UserController.sharedInstance.getLoggedInUser()?.email)  {
            
            
            return (XorO == CellType.X)
        }   else    {
            return (XorO == CellType.O)
            
        }
    }
    
    //returns user type at a specific board index
    func typeAtIndex(pos:Int) -> CellType! {
        return board[pos]
    }
    
    //one of the later functions created in the demo
    //execute the move in the game
    func playMove(position:Int) -> CellType! {
        board[position] = whosTurn()
        return board[position]
    }
    
    func winDetection() -> Bool {
        
        //Check rows
        for i in 0...2 {
            if((board[3*i] == board[3*i + 1]) && (board[3*i] == board[3*i + 2]) && !(String(board[3*i]) == "EMPTY")){
                print("Someone won at row i")
                print(i)
                print( board[i])
                return true
            }
        }
        
        //Check columns
        for j in 0...2 {
            if((board[j] == board[j + 3]) && (board[j] == board[j + 6]) && !(String(board[j]) == "EMPTY")){
                print("Someone won at column j")
                print(j)
                print( board[j])
                return true
            }
        }
        
        //Check diagonals
        if((board[0] == board[4]) && (board[0] == board[8]) && !(String(board[0]) == "EMPTY")){
            print("Someone won at diagonal 1")
            return true
        }
        if((board[2] == board[4]) && (board[2] == board[6]) && !(String(board[2]) == "EMPTY")){
            print("Someone won at diagonal 2")
            return true
        }
        
        return false
        
    }
    
    //the current state of the game
    func state() -> OXGameState    {
        
        //check if someone won on this turn
        let win = winDetection()
        
        //if noone won, game is still in progress
        if (win)   {
            return OXGameState.complete_someone_won
        } else if (turn() == 9) {
            return OXGameState.complete_no_one_won
        } else    {
            return OXGameState.inProgress
        }
        
    }
    
    //restart the game
    func reset()    {
        board = [CellType](count: 9, repeatedValue: CellType.EMPTY)
        print("Reseting")
    }
    
    
}


class OXGameController: WebService {
    
    private var currentGame: OXGame?

    class var sharedInstance: OXGameController {
        struct Static {
            static var instance:OXGameController?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token)    {
            Static.instance = OXGameController()
        }
        return Static.instance!
        
    }
    
    
    //Called when an user in an active game want to end the game before its finished
    func cancelGame(gameId:String, presentingViewController:UIViewController? = nil, viewControllerCompletionFunction:(Bool,String?) -> ()) {
        
        //remember a request has 4 things:
        //1: A endpoint
        //2: A method
        //3: input data (optional)
        //4: A response
        let request = self.createMutableRequest(NSURL(string: "https://ox-backend.herokuapp.com/games/\(gameId)"), method: "DELETE", parameters: nil)
        
        //execute request is a function we are able to call in OXGameController, because OXGameController extends WebService (See top of file, where OXGameController is defined)
        self.executeRequest(request, presentingViewController:presentingViewController, requestCompletionFunction: {(responseCode, json) in
            
            //Here is our completion closure for the web request. when the web service is done, this is what is executed.
            //Not only is the code in this block executed, but we are given 2 input parameters, responseCode and json.
            //responseCode is the response code from the server.
            //json is the response data received
            
            print(json)
            
            if (responseCode / 100 == 2)   { //if the responseCode is 2xx (any responseCode in the 200's range is a success case. For example, some servers return 201 for successful object creation)
                
                //successfully deleted the game, no data to return needed
                
                //lets execute that closure now - Lets me be clear. This is 1 step more advanced than normal. We are executing a closure inside a closure (we are executing the viewControllerCompletionFunction from within the requestCompletionFunction.
                viewControllerCompletionFunction(true,nil)
            }   else    {
                //the web service to create a user failed. Lets extract the error message to be displayed
                
                let errorMessage = json["errors"]["full_messages"][0].stringValue
                
                //execute the closure in the ViewController
                viewControllerCompletionFunction(false, errorMessage)
            }
            
        })
        
        //we are now done with the registerUser function. Note that this function doesnt return anything. But because of the viewControllerCompletionFunction closure we are given as an input parameter, we can set in motion a function in the calling class when it is needed.
        
    }
    
    
    
    // this function returns a array of OXGAmes available from the web. if the webs service fails for some reason it returns nil for the OXGame array, and a message instead to show the user for reason o ffailure
    func gameList(presentingViewController:UIViewController? = nil, viewControllerCompletionFunction:([OXGame]?,String?) -> ()) {
        
        //remember a request has 4 things:
        //1: A endpoint
        //2: A method
        //3: input data (optional)
        //4: A response
        let request = self.createMutableRequest(NSURL(string: "https://ox-backend.herokuapp.com/games"), method: "GET", parameters: nil)
        
        //execute request is a function we are able to call in OXGameController, because OXGameController extends WebService (See top of file, where OXGameController is defined)
        self.executeRequest(request, presentingViewController:presentingViewController, requestCompletionFunction: {(responseCode, json) in
            
            //Here is our completion closure for the web request. when the web service is done, this is what is executed.
            //Not only is the code in this block executed, but we are given 2 input parameters, responseCode and json.
            //responseCode is the response code from the server.
            //json is the response data received
            
            print(json)
            
            if (responseCode / 100 == 2)   { //if the responseCode is 2xx (any responseCode in the 200's range is a success case. For example, some servers return 201 for successful object creation)
                
                //successfully received the game list
                var list:[OXGame]? = []
                
                //lets populate the list var with the game data received
                for (str, game) in json    {
                    var game = OXGame(json: game)
                    if (game.backendState == OXGameState.open)   {
                        list?.append(game)
                    }
                    
                }
                
                //lets execute that closure now - Lets me be clear. This is 1 step more advanced than normal. We are executing a closure inside a closure (we are executing the viewControllerCompletionFunction from within the requestCompletionFunction.
                viewControllerCompletionFunction(list,nil)
            }   else    {
                //the web service to create a user failed. Lets extract the error message to be displayed
                
                let errorMessage = json["errors"]["full_messages"][0].stringValue
                
                //execute the closure in the ViewController
                viewControllerCompletionFunction(nil, errorMessage)
            }
            
        })
        
        //we are now done with the registerUser function. Note that this function doesnt return anything. But because of the viewControllerCompletionFunction closure we are given as an input parameter, we can set in motion a function in the calling class when it is needed.
        
    }
    
    
    //Can only be called when there is an active game
    func playMove(board: String, gameId:String, presentingViewController:UIViewController? = nil, viewControllerCompletionFunction:(OXGame?,String?) -> ())  {
        
        
        //remember a request has 4 things:
        //1: A endpoint
        //2: A method
        //3: input data (optional)
        //4: A response
        
        var params = ["board":board]
        let request = self.createMutableRequest(NSURL(string: "https://ox-backend.herokuapp.com/games/\(gameId)"), method: "PUT", parameters: params)
        
        //execute request is a function we are able to call in OXGameController, because OXGameController extends WebService (See top of file, where OXGameController is defined)
        self.executeRequest(request, presentingViewController:presentingViewController, requestCompletionFunction: {(responseCode, json) in
            
            //Here is our completion closure for the web request. when the web service is done, this is what is executed.
            //Not only is the code in this block executed, but we are given 2 input parameters, responseCode and json.
            //responseCode is the response code from the server.
            //json is the response data received
            
            print(json)
            
            if (responseCode / 100 == 2)   { //if the responseCode is 2xx (any responseCode in the 200's range is a success case. For example, some servers return 201 for successful object creation)
                
                let game = OXGame(json: json)
                
                //lets execute that closure now - Lets me be clear. This is 1 step more advanced than normal. We are executing a closure inside a closure (we are executing the viewControllerCompletionFunction from within the requestCompletionFunction.
                viewControllerCompletionFunction(game,nil)
            }   else    {
                //the web service to create a user failed. Lets extract the error message to be displayed
                
                let errorMessage = json["errors"]["full_messages"][0].stringValue
                
                //execute the closure in the ViewController
                viewControllerCompletionFunction(nil, errorMessage)
            }
            
        })
        
        //we are now done with the registerUser function. Note that this function doesnt return anything. But because of the viewControllerCompletionFunction closure we are given as an input parameter, we can set in motion a function in the calling class when it is needed.
        
        
    }
    
    //Can only be called when there is an active game
    func getGame(gameId:String, presentingViewController:UIViewController? = nil, viewControllerCompletionFunction:(OXGame?,String?) -> ())  {
        
        
        //remember a request has 4 things:
        //1: A endpoint
        //2: A method
        //3: input data (optional)
        //4: A response
        
        let request = self.createMutableRequest(NSURL(string: "https://ox-backend.herokuapp.com/games/\(gameId)"), method: "GET", parameters: nil)
        
        //execute request is a function we are able to call in OXGameController, because OXGameController extends WebService (See top of file, where OXGameController is defined)
        self.executeRequest(request, presentingViewController:presentingViewController, requestCompletionFunction: {(responseCode, json) in
            
            //Here is our completion closure for the web request. when the web service is done, this is what is executed.
            //Not only is the code in this block executed, but we are given 2 input parameters, responseCode and json.
            //responseCode is the response code from the server.
            //json is the response data received
            
            print(json)
            
            if (responseCode / 100 == 2)   { //if the responseCode is 2xx (any responseCode in the 200's range is a success case. For example, some servers return 201 for successful object creation)
                
                let game = OXGame(json: json)
                
                //lets execute that closure now - Lets me be clear. This is 1 step more advanced than normal. We are executing a closure inside a closure (we are executing the viewControllerCompletionFunction from within the requestCompletionFunction.
                viewControllerCompletionFunction(game,nil)
            }   else    {
                //the web service to create a user failed. Lets extract the error message to be displayed
                
                let errorMessage = json["errors"]["full_messages"][0].stringValue
                
                //execute the closure in the ViewController
                viewControllerCompletionFunction(nil, errorMessage)
            }
            
        })
        
        //we are now done with the registerUser function. Note that this function doesnt return anything. But because of the viewControllerCompletionFunction closure we are given as an input parameter, we can set in motion a function in the calling class when it is needed.
        
        
    }
    
    
    //Simple random move, it will always try to play the first indexes
    func playRandomMove() -> (CellType, Int)? {
        print("Playing random move")
        if let count = currentGame?.board.count {
            for i in 0...count - 1 {
                if (currentGame?.board[i] == CellType.EMPTY){
                    let cellType: CellType = (currentGame?.playMove(i))!
                    print(cellType)
                    print("Succesfully at: " + String(i))
                    return (cellType, i)
                }
            }
        }
        print("Unsuccesfully")
        return nil
        
    }
    
    func createNewGame(host:User, presentingViewController:UIViewController? = nil, viewControllerCompletionFunction:(OXGame?,String?) -> ())   {
        print("Creating new network game")
        
        //remember a request has 4 things:
        //1: A endpoint
        //2: A method
        //3: input data (optional)
        //4: A response
        let request = self.createMutableRequest(NSURL(string: "https://ox-backend.herokuapp.com/games/"), method: "POST", parameters: nil)
        
        //execute request is a function we are able to call in OXGameController, because OXGameController extends WebService (See top of file, where OXGameController is defined)
        self.executeRequest(request, presentingViewController:presentingViewController, requestCompletionFunction: {(responseCode, json) in
            
            //Here is our completion closure for the web request. when the web service is done, this is what is executed.
            //Not only is the code in this block executed, but we are given 2 input parameters, responseCode and json.
            //responseCode is the response code from the server.
            //json is the response data received
            
            print(json)
            
            if (responseCode / 100 == 2)   { //if the responseCode is 2xx (any responseCode in the 200's range is a success case. For example, some servers return 201 for successful object creation)
                
                //lets populate the list var with the game data received
                let game = OXGame(json: json)
                
                //lets execute that closure now - Lets me be clear. This is 1 step more advanced than normal. We are executing a closure inside a closure (we are executing the viewControllerCompletionFunction from within the requestCompletionFunction.
                viewControllerCompletionFunction(game,nil)
            }   else    {
                //the web service to create a user failed. Lets extract the error message to be displayed
                
                let errorMessage = json["errors"]["full_messages"][0].stringValue
                
                //execute the closure in the ViewController
                viewControllerCompletionFunction(nil, errorMessage)
            }
            
        })
        
        //we are now done with the acceptGame function. Note that this function doesnt return anything. But because of the viewControllerCompletionFunction closure we are given as an input parameter, we can set in motion a function in the calling class when it is needed.
        
        
    }
    
    
    func acceptGame(id:String, presentingViewController:UIViewController? = nil, viewControllerCompletionFunction:(OXGame?,String?) -> ()) {
        
        
        //remember a request has 4 things:
        //1: A endpoint
        //2: A method
        //3: input data (optional)
        //4: A response
        let request = self.createMutableRequest(NSURL(string: "https://ox-backend.herokuapp.com/games/\(id)/join"), method: "GET", parameters: nil)
        
        //execute request is a function we are able to call in OXGameController, because OXGameController extends WebService (See top of file, where OXGameController is defined)
        self.executeRequest(request, presentingViewController:presentingViewController, requestCompletionFunction: {(responseCode, json) in
            
            //Here is our completion closure for the web request. when the web service is done, this is what is executed.
            //Not only is the code in this block executed, but we are given 2 input parameters, responseCode and json.
            //responseCode is the response code from the server.
            //json is the response data received
            
            print(json)
            
            if (responseCode / 100 == 2)   { //if the responseCode is 2xx (any responseCode in the 200's range is a success case. For example, some servers return 201 for successful object creation)
                
                //lets obtain the returned game data received
                let game = OXGame(json: json)
                
                //lets execute that closure now - Lets me be clear. This is 1 step more advanced than normal. We are executing a closure inside a closure (we are executing the viewControllerCompletionFunction from within the requestCompletionFunction.
                viewControllerCompletionFunction(game,nil)
            }   else    {
                //the web service to create a user failed. Lets extract the error message to be displayed
                
                let errorMessage = json["errors"]["full_messages"][0].stringValue
                
                //execute the closure in the ViewController
                viewControllerCompletionFunction(nil, errorMessage)
            }
            
        })
        
        //we are now done with the acceptGame function. Note that this function doesnt return anything. But because of the viewControllerCompletionFunction closure we are given as an input parameter, we can set in motion a function in the calling class when it is needed.
    }
}