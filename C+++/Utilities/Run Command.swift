//
//  Run Command.swift
//  C+++
//
//  Created by 23786 on 2020/8/1.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Foundation

/** Run a shell command.
 - parameter command: The command.
 - parameter stdin: The stantard input.
 - returns: If no error ocurred, return a string array with only one item (stantard output).
   If an error ocurred, return a string array with two items (stantard output and stantard error).
*/

func runShellCommand(_ command: String, _ stdin: String = "", terminationHandler:  @escaping ([String]) -> Void) {
    
    DispatchQueue(label: "CpppCommandRun").async {
        
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        let inputPipe = Pipe()
        inputPipe.fileHandleForWriting.write(stdin.data(using: .utf8)!)
        
        task.standardOutput = pipe
        task.standardError = errorPipe
        task.standardInput = inputPipe
        task.terminationHandler = { task in
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
            
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput: String = NSString(data: errorData, encoding: String.Encoding.utf8.rawValue)! as String
            
            if errorOutput == "" {
                DispatchQueue.main.async {
                    terminationHandler([output])
                    return
                }
            }
            DispatchQueue.main.async {
                terminationHandler([output, errorOutput])
            }
            
        }
        task.launch()
        
    }
    
}


func processForShellCommand(command: String) -> Process {
    
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", command]
    
    return task
    
}
