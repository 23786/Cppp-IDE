//
//  CDServer.swift
//  C+++
//
//  Created by 张一鸣 on 2021/2/17.
//  Copyright © 2021 Zhu Yixuan. All rights reserved.
//

/*import Foundation
import PerfectLib
import PerfectNet
import PerfectThread
import PerfectHTTP
import PerfectHTTPServer

fileprivate var _sharedServer = CDServer()

class CDServer : NSObject {
    
    func start() {
        
        let ccRoute = Route(method: .post, uri: "/", handler: {
            req, res in
            
            guard req.postBodyString != nil else {
                return
            }
            
            let json = try! JSONSerialization.jsonObject(with: (req.postBodyString?.data(using: .utf8))!, options: .mutableContainers) as Any
            let tests = json["tests"] as! [Any]
            var inputs = [String](), outputs = [String]()
            
            for test in tests {
                inputs.append(test["input"] as! String)
                outputs.append(test["output"] as! String)
            }
            
            DispatchQueue.main.async {
                
                let newDocument = CDCodeDocument()
                
                newDocument.content = CDDocumentContent(contentString: """
                //
                // Problem Name: \(json["name"] as! String)
                // Problem Link: \(json["url"] as! String)
                // Memory Limit: \(json["memoryLimit"] as! Int)
                // Time Limit: \(json["timeLimit"] as! Int)
                //
                """)
                
                GlobalMainWindowController.addDocument(newDocument)
                if inputs.count != 0 {
                    GlobalMainWindowController.mainViewController.consoleView.runView.input?.text = inputs[0]
                    GlobalMainWindowController.mainViewController.consoleView.runView.expectedOutput?.text = outputs[0]
                }
                
            }
            
        })
        
        let serialQueue = DispatchQueue(label: "", qos: .default, attributes: [.concurrent], autoreleaseFrequency: .inherit, target: nil)
        serialQueue.async {
            do {
                try HTTPServer.launch(name: "localhost", port: 10043, routes: [ccRoute])
            } catch {
                print(error)
            }
        }
        
    }
    
    class var shared: CDServer {
        return _sharedServer
    }
    
}
*/
