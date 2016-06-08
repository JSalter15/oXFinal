//
//  ClosureExperiment.swift
//  NoughtsAndCrosses
//
//  Created by Alejandro Castillejo on 6/6/16.
//  Copyright © 2016 Julian Hulme. All rights reserved.
//

import Foundation

class ClosureExperiment {
    
    init() {
        //experiment 1
        self.thisIsAFunction("the string variable", withAClosure:self.anotherFunction)
        //self.anotherFunction()
        
        //experiment 2
        self.thisIsAFunction("input var", withAClosureWithAInputParameter: {(variableName) in self.thisIsAFunctionWithAInputParameter(variableName)})
        
    }
    
    func thisIsAFunction(withAInputVariable:String, withAClosure:() -> ())    {
        print("thisIsAFunction is executing")
        withAClosure() //this function will be executed when this line occurs
    }
    
    func anotherFunction()  {
        print("another function is executing")
    }
    
    //experiment 2
    //self.thisIsAFunction("input var", withAClosureWithAInputParameter: {(variableName) in self.thisIsAFunctionWithAInputParameter(variableName)})
    func thisIsAFunction(withAInputVariable:String, withAClosureWithAInputParameter:(closureInput:String) -> ())    {
        print("thisIsAFunction is executing \(withAInputVariable)")
        let valueCreatedInFunction = "hi there"
        withAClosureWithAInputParameter(closureInput: valueCreatedInFunction)
        
    }
    
    func thisIsAFunctionWithAInputParameter(param:String)   {
        print ("another")
    }
    
}