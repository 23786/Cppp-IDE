//
//  CDLanguageServerClient.swift
//  C+++
//
//  Created by 23786 on 2021/1/3.
//  Copyright © 2021 Zhu Yixuan. All rights reserved.
//

import Cocoa

// TODO
extension Notification.Name {
    static let languageServerDidOpenDocument = NSNotification.Name(rawValue: "LanguageServerDidOpenDocument")
    static let languageServerDidInit = NSNotification.Name(rawValue: "LanguageServerDidInit")
    static let languageServerDidQuit = NSNotification.Name(rawValue: "LanguageServerDidQuit")
}

class CDLanguageServerClient: NSObject {
    
    private var process: Process?
    private let inputPipe = Pipe()
    private let outputPipe = Pipe()
    private let errorPipe = Pipe()
    private var id: Int = 1
    private var isProcessRunning = false
    private var completeFlag = true
    private var incompleteData = Data()
    private var documentVersions: [String : Int] = [ : ]
    var delegate: CDLanguageServerClientDelegate?
    
    func startServer(path: String = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clangd", arguments: [String] = [ ]) {
        
        DispatchQueue(label: "LanguageServer", qos: .utility).sync {
            
            let process = Process()
            process.launchPath = path
            process.arguments = arguments
            
            process.standardInput = self.inputPipe
            process.standardOutput = self.outputPipe
            process.standardError = self.errorPipe
            
            self.outputPipe.fileHandleForReading.readabilityHandler = { (fileHandle) in
                
                var dataToRead = fileHandle.availableData
                
                if !self.readResponse(dataToRead) {
                    dataToRead = self.incompleteData + dataToRead
                    if !self.readResponse(dataToRead) {
                        self.incompleteData = dataToRead
                    } else {
                        self.incompleteData = Data()
                    }
                    
                } else {
                    self.incompleteData = Data()
                }
                
            }
            
            process.launch()
            NotificationCenter.default.post(Notification(name: .languageServerDidInit))
            isProcessRunning = true
            process.terminationHandler = { (process) in
                print("LSP Exited")
                self.isProcessRunning = false
                NotificationCenter.default.post(Notification(name: .languageServerDidQuit))
            }
            
            self.id = 1
            
            let request = CDLSPRequest(
                method: "initialize",
                id: self.id,
                params: [ : ]
            )
            
            self.writeRequest(request)
            
        }
        
    }
    
    func openDocument(path: String, content: String) {
        
        documentVersions[path] = 1
        let noti = CDLSPNotification(
            method: "textDocument/didOpen",
            params: [
                "textDocument": [
                    "languageId": "cpp",
                    "text": content,
                    "uri": URL(fileURLWithPath: path).absoluteString,
                    "version": 1
                ]
            ]
        )
        self.writeNotification(noti)
        NotificationCenter.default.post(Notification(name: .languageServerDidOpenDocument))
        
    }
    
    func closeDocument(path: String) {
        
        let noti = CDLSPNotification(
            method: "textDocument/didClose",
            params: [
                "textDocument" : [
                    "uri": URL(fileURLWithPath: path).absoluteString
                ]
            ]
        )
        self.writeNotification(noti)
        
    }
    
    func didChangeText(path: String, newText: String) {
        
        if documentVersions.keys.contains("path") {
            documentVersions["path"]! += 1
        } else {
            documentVersions["path"] = 1
        }
        let noti = CDLSPNotification(
            method: "textDocument/didChange",
            params: [
                "textDocument" : [
                    "uri": URL(fileURLWithPath: path).absoluteString,
                    "version": documentVersions["path"]!
                ],
                "contentChanges" : [
                    ["text": newText]
                ]
            ]
        )
        self.writeNotification(noti)
        
    }
    
    func completion(path: String, line: Int, character: Int) {
        
        self.id += 1
        let request = CDLSPRequest(
            method: "textDocument/completion",
            id: self.id,
            params: [
                "textDocument" : [
                    "uri": URL(fileURLWithPath: path).absoluteString
                ],
                "position" : [
                    "line": line,
                    "character": character
                ]
            ]
        )
        self.writeRequest(request)
        
    }
    
    private func writeRequest(_ request: CDLSPRequest) {
        
        DispatchQueue(label: "LanguageServer", qos: .utility).async {
            let data = try? request.toData()
            guard data != nil else {
                return
            }
            if self.isProcessRunning {
                self.inputPipe.fileHandleForWriting.write(data!)
            }
        }
        
    }
    
    
    private func writeNotification(_ not: CDLSPNotification) {
        
        DispatchQueue(label: "LanguageServer", qos: .utility).async {
            let data = try? not.toData()
            guard data != nil else {
                return
            }
            if self.isProcessRunning {
                self.inputPipe.fileHandleForWriting.write(data!)
            }
        }
        
    }

    
}
 
