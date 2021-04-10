//
//  CDCompileResultAndConsoleView.swift
//  C+++
//
//  Created by 23786 on 2020/8/1.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa
import SwiftTermMac

class CDCompileResultAndDebugView: NSView {
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var errorCountLabel: NSTextField!
    @IBOutlet weak var errorImageLabel: NSImageView!
    @IBOutlet weak var warningCountLabel: NSTextField!
    @IBOutlet weak var warningImageView: NSImageView!
    @IBOutlet weak var commandTextField: NSTextField!
    @IBOutlet weak var debugTextView: NSTextView!
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    
    @IBOutlet weak var logView: NSTextView!
    @IBOutlet weak var compileResultTableView: NSTableView!
    
    @IBOutlet weak var debugSplitView: NSSplitView!
    @IBOutlet weak var resultAndRunSplitView: NSSplitView!
    @IBOutlet weak var runView: CDTestPointRunView!
    @IBOutlet weak var watchVarsTableView: NSTableView!
    
    
    private var inputPipe: Pipe?
    private var errorPipe: Pipe?
    private var outputPipe: Pipe?
    private var runProcess: Process?
    
    var compileResult: CDCompileResult? {
        didSet {
            self.compileResultTableView.dataSource = self.compileResult
            self.errorCountLabel.stringValue = "\(self.compileResult?.errorCount ?? 0)"
            self.warningCountLabel.stringValue = "\(self.compileResult?.warningCount ?? 0)"
        }
    }
    

    private func sendInput(_ string: String) {
        (self.window?.windowController?.document as! CDCodeDocument).sendInputToDebugger(message: string)
    }
    
    @IBAction func run(_ sender: Any?) {
        self.sendInput("run")
    }
    
    @IBAction func next(_ sender: Any?) {
        self.sendInput("next")
    }
    
    @IBAction func `continue`(_ sender: Any?) {
        self.sendInput("continue")
    }
    
    @IBAction func stepIn(_ sender: Any?) {
        self.sendInput("step")
    }
    
    @IBAction func stepOut(_ sender: Any?) {
        self.sendInput("finish")
    }
    
    @IBAction func quit(_ sender: Any?) {
        self.sendInput("quit")
    }
    
    @IBAction func frameVariable(_ sender: Any?) {
        self.sendInput("frame variable")
    }
    
    @IBAction func addWatchVar(_ sender: Any?) {
        CDGetInput(title: "Watch Var Name:", placeholder: "i") { input in
            (self.window?.windowController?.document as! CDCodeDocument).debugger?.addWatchVar(variableName: input)
            self.watchVarsTableView.reloadData()
        }
    }
    
    @IBAction func sendInput(_ sender: Any?) {
        sendInput(self.commandTextField.stringValue)
    }
    
    @IBAction func runTestPoint(_ sender: Any?) {
        
        guard let name = (self.window?.windowController?.document as? NSDocument)?.fileURL?.deletingPathExtension().path else {
            return
        }
        
        if !FileManager.default.fileExists(atPath: name) {
            (self.window?.windowController?.document as? CDCodeDocument)?.compileFile(nil)
        }

        self.runProcess = ProcessForShellCommand(command: "\"" + name + "\"" + " " + CDSettings.runArguments)
        inputPipe = Pipe()
        errorPipe = Pipe()
        outputPipe = Pipe()
        inputPipe?.fileHandleForWriting.write( ((self.runView.input?.string ?? "") + "\nEOF\n").data(using: .utf8)! )
        
        runProcess?.standardInput = self.inputPipe
        runProcess?.standardError = self.errorPipe
        runProcess?.standardOutput = self.outputPipe
        
        self.runView?.stateLabel?.stringValue = "Running"
        
        let date = Date()
        runProcess?.terminationHandler = { (process) in
            
            let string = String(format: "%.2lfs ", -date.timeIntervalSinceNow)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                
                if self.runView.stateLabel!.stringValue.contains("TLE") {
                    return
                }
                
                let data = self.outputPipe!.fileHandleForReading.readDataToEndOfFile()
                self.runView.actualOutput?.string = String(data: data, encoding: .utf8) ?? "Error"
                self.runView.stateLabel?.stringValue = string
                
                if process.terminationStatus != 0 {
                    self.runView.stateLabel?.stringValue += "RE"
                    return
                }
                
                if !(self.runView.expectedOutput?.isHidden ?? true) {
                    let linesA = self.runView.actualOutput!.string.components(separatedBy: "\n")
                    let linesE = self.runView.expectedOutput!.string.components(separatedBy: "\n")
                    var i = 0
                    while i < linesA.count || i < linesE.count {
                        let lhs: String
                        let rhs: String
                        if i >= linesA.count {
                            lhs = ""
                        } else {
                            lhs = linesA[i].trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        if i >= linesE.count {
                            rhs = ""
                        } else {
                            rhs = linesE[i].trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        if lhs != rhs {
                            self.runView.stateLabel?.stringValue += "WA"
                            return
                        }
                        i += 1
                    }
                    self.runView.stateLabel?.stringValue += "AC"
                }
                
            }
        }
        runProcess?.launch()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + CDSettings.timeLimit) {
            if self.runProcess?.isRunning ?? false {
                self.runProcess?.terminate()
                self.runView.stateLabel?.stringValue = String(format: "%.2lfs TLE", CDSettings.timeLimit)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.6) {
                    self.runView?.actualOutput?.string = "Time Limit Exceeded, automatically stopped running."
                }
            }
        }
        
        
    }
    
}
