//
//  CDDebugger.swift
//  C+++
//
//  Created by 23786 on 2020/10/7.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa

class CDDebugger: NSObject {
    
    private var filePath: String = ""
    private var debugTask: Process?
    private var pipe: Pipe?
    private var errorPipe: Pipe?
    var delegate: CDDebuggerDelegate?
    private(set) var watchVars: [CDDebugWatchVar] = []
    private var watchVarIndex = 0
    private var breakpoints: [CDDebuggerBreakpoint] = []
    private var breakpointMaxIndex = 1
    
    func addBreakpoint(line: Int) {
        
        for item in self.breakpoints {
            if item.line == line {
                return
            }
        }
        
        self.breakpoints.append( CDDebuggerBreakpoint(line: line, index: breakpointMaxIndex) )
        breakpointMaxIndex += 1
        
        if self.debugTask?.isRunning ?? false {
            self.sendCommand(command: "breakpoint set --line \(line)")
        }
        
    }
    
    func removeBreakpoint(line: Int) {
        
        var index = 0
        
        for item in self.breakpoints {
            
            if item.line == line {
                
                self.breakpoints.remove(at: index)
                
                if self.debugTask?.isRunning ?? false {
                    self.sendCommand(command: "breakpoint delete \(item.index)")
                }
                
            }
            
            index += 1
            
        }
        
    }
    
    init(filePath: String) {
        super.init()
        self.filePath = filePath
    }
    
    func begin() {
        
        self.end()
        
        let url = URL(string: self.filePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!
        CDCodeDocument.compileFile(fileURL: url, alsoRuns: false, arguments: "-g") { (res) in
            
            if !(res.result?.succeed ?? false) {
                self.delegate?.compileFailed()
                return
            }
            
            self.debugTask = Process()
            self.debugTask?.launchPath = "/bin/bash"
            self.debugTask?.arguments = ["-c", "lldb \"\(self.filePath.nsString.deletingPathExtension)\""]
            
            let pipe = Pipe()
            self.pipe = Pipe()
            self.debugTask?.standardOutput = pipe
            self.debugTask?.standardError = pipe
            self.debugTask?.standardInput = self.pipe
            let outHandle = pipe.fileHandleForReading
            
            outHandle.readabilityHandler = { pipe in
                
                if let data = String(data: pipe.availableData, encoding: .utf8) {
                    if data != "" {
                        DispatchQueue.main.sync {
                            self.received(input: data)
                            self.delegate?.received(text: data, from: self)
                        }
                    }
                } else {
                    Swift.print("Error decoding data: \(pipe.availableData)")
                }
                
            }
            
            self.debugTask?.launch()
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
                
                for bp in self.breakpoints {
                    self.sendCommand(command: "breakpoint set --line \(bp.line)")
                }
                
                var index = 1
                for v in self.watchVars {
                    self.sendCommand(command: "display \(v.name)")
                    self.watchVars[index - 1].index = index
                    index += 1
                }
                
            }
            
        }
        
    }
    
    func end() {
        
       //  self.processView.
        
    }
    
    private func received(input: String) {
        
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        func parseWatchVar(input: String) {
            
            var str = input // mutable copy
            // Delete "- Hook "
            str.removeSubrange( ..<str.index(str.startIndex, offsetBy: 7) )
            guard let spaceIndex = str.firstIndex(of: " ") else {
                return
            }
            let hookNumberStr = str[ ..<spaceIndex ]
            guard let hookNumber = Int(hookNumberStr) else {
                return
            }
            guard input.components(separatedBy: "\n").count >= 2 else {
                return
            }
            let newVal = input.components(separatedBy: .newlines)[1]
            self.delegate?.watchVarRefreshed(varIndex: hookNumber, newValue: newVal)
            self.watchVars.first(where: { (item) in
                return item.index == hookNumber
            })?.value = newVal
            
        }
        
        func parseCurrentLineNumber(input: String) {
            
            for line in input.components(separatedBy: "\n") {
                // -> [Line Number] [Code]
                if line.hasPrefix("->") {
                    var l = line // mutable copy
                    l.removeSubrange( ..<l.index(l.startIndex, offsetBy: 3) )
                    guard let spaceIndex = l.firstIndex(of: " ") else {
                        continue
                    }
                    let lineNumberStr = l[ ..<spaceIndex ]
                    guard let lineNumber = Int(lineNumberStr) else {
                        continue
                    }
                    self.delegate?.currentLineMoved(to: lineNumber)
                    break
                }
            }
            
        }
        
        
        if trimmed.hasPrefix("- Hook ") { // - Hook [number] (expr -- [Expression])
            parseWatchVar(input: trimmed)
        } else if trimmed.hasPrefix("Process ") { // Process [number] stopped.
            parseCurrentLineNumber(input: trimmed)
        }
        
        
    }
    
    func sendCommand(command: String) {
        if self.debugTask?.isRunning ?? false {
            self.pipe?.fileHandleForWriting.write( (command + "\n").data(using: .utf8)! )
        }
    }
    
    func addWatchVar(variableName name: String) {
        
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        for v in self.watchVars {
            if v.name == n {
                return
            }
        }
        
        watchVarIndex += 1
        
        if self.debugTask?.isRunning ?? false {
            
            self.watchVars.append( CDDebugWatchVar(name: n, index: watchVarIndex) )
            self.sendCommand(command: "display \(n)")
            
        } else {
            
            self.watchVars.append( CDDebugWatchVar(name: n) )
            
        }
        
    }
    
    func removeWatchVar(variableName name: String) {
        
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var index = 0
        
        for v in self.watchVars {
            if v.name == n {
                break
            }
            index += 1
        }
        
        self.watchVars.remove(at: index)
        self.sendCommand(command: "undisplay \(self.watchVars[index].index ?? -1)")
        
    }
    
}
