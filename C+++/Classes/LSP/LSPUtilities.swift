//
//  LSPUtilities.swift
//  C+++
//
//  Created by 23786 on 2021/2/9.
//  Copyright © 2021 Zhu Yixuan. All rights reserved.
//

import Cocoa


struct CDLSPError: Error, CustomStringConvertible {
    
    var error: String
    
    init(description: String) {
        self.error = description
    }
    
    var description: String {
        return "CDLanguageServerError: \(self.error)"
    }
    
    static var incompleteError: CDLSPError {
        return CDLSPError(description: "Data not complete.")
    }
    
}

protocol CDLSPBase: NSObject {
    
    var method: String { get }
    
}

func CDLSPProcessDataFromServer(from data: Data) throws -> CDLSPBase {
    
    // Step #1: Check data legality
    
    guard let str = String(data: data, encoding: .utf8) else {
        throw CDLSPError(description: "Error found when decoding data.")
    }
    
    if str.isEmpty {
        throw CDLSPError(description: "Empty String.")
    }
    
    // Variable Definition
    var id: Int = -1
    var method: String = ""
    
    let components = str.components(separatedBy: "\r\n")
    var res: CDLSPBase?
    
    var givenLength = data.count - (components.count - 1) * 2
    var completeLength = -1
    
    // Step #2: Check data completion
    
    for component in components {
        do {
            if component.hasPrefix("Content-Length: ") {
                completeLength = Int(component.replacingOccurrences(of: "Content-Length: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? -1
                givenLength -= component.count
            }
        }
    }
    
    print(completeLength, givenLength)
    if completeLength > givenLength || completeLength == -1 {
        throw CDLSPError.incompleteError
    }
    
    
    for component in components {
        do {
            let dictionary = try JSONSerialization.jsonObject(with: component.data(using: .utf8)!) as? Dictionary<String, Any>
            guard let dict = dictionary else {
                continue
            }
            
            if dict.keys.contains("id") {
                id = dict["id"] as? Int ?? -1
            }
            
            if dict.keys.contains("error") {
                let error = dict["error"] as! Dictionary<String, Any>
                throw CDLSPError(description: "Error from language server: \(error["message"] ?? "<Get Error Description Failed.>")")
            }
            
            if dict.keys.contains("method") {
                method = dict["method"] as? String ?? ""
            }
            
            if dict.keys.contains("result") {
                let result = dict["result"] as! Dictionary<String, Any>
                res = CDLSPResponse(id: id, method: method, res: result)
            } else if dict.keys.contains("params") {
                let params = dict["params"] as! Dictionary<String, Any>
                if id == -1 {
                    res = CDLSPNotification(method: method, params: params)
                } else {
                    res = CDLSPRequest(method: method, id: id, params: params)
                }
            }
            
        } catch {
            if error is CDLSPError {
                throw error
            }
            continue
        }
    }
    
    if res != nil {
        return res!
    } else {
        throw CDLSPError(description: "Error found when decoding data.")
    }
    
}



struct CDLSPSourceFileLocation {
    
    var line: Int = 0
    var character: Int = 0
    
    init(dict: [String : Any]) {
        self.line = dict["line"] as! Int
        self.character = dict["character"] as! Int
    }
    
}

struct CDLSPSourceFileRange {
    
    var start: CDLSPSourceFileLocation
    var end: CDLSPSourceFileLocation
    
    init(dict: [String : Any]) {
        self.start = CDLSPSourceFileLocation(dict: dict["start"] as! [String : Any])
        self.end = CDLSPSourceFileLocation(dict: dict["end"] as! [String : Any])
    }
    
}

struct CDDiagnostic {
    
    enum Severity: Int {
        case error = 1
        case warning = 2
        case information = 3
        case hint = 4
    }
    
    var code: String? = ""
    var message: String? = ""
    var range: CDLSPSourceFileRange?
    var severity: Severity? = .error
    var source: String? = ""
    
    init(dict: [String : Any]) {
        self.code = dict["code"] as? String
        self.message = dict["message"] as? String
        let raw = dict["severity"] as? Int
        if raw != nil {
            self.severity = Severity(rawValue: raw!)
        }
        self.source = dict["source"] as? String
        self.range = CDLSPSourceFileRange(dict: dict["range"] as! [String : Any])
    }
    
}

// MARK: - Completion

struct CDLSPCompletionList {
    
    var isIncomplete: Bool = false
    var items: [CDLSPCompletionItem] = []
    
}

struct Command {
    // nothing
}

struct CDLSPTextEdit {
    
    var range: CDLSPSourceFileRange
    var newText: String
    
}


struct CDLSPCompletionItem {
    
    enum CompletionItemTag: Int {
        case deprecated = 1
    }

    enum CompletionItemKind: Int {
        case text = 1
        case method = 2
        case function = 3
        case constructor = 4
        case field = 5
        case variable = 6
        case `class` = 7
        case interface = 8
        case module = 9
        case property = 10
        case unit = 11
        case value = 12
        case `enum` = 13
        case keyword = 14
        case snippet = 15
        case color = 16
        case file = 17
        case reference = 18
        case folder = 19
        case enumMember = 20
        case constant = 21
        case `struct` = 22
        case event = 23
        case `operator` = 24
        case typeParameter = 25
    }
    
    enum InsertTextFormat: Int {
        case plainText = 1
        case snippet = 2
    }
    
    enum InsertTextMode: Int {
        case asIs = 1
        case adjustIndentation = 2
    }
    
    struct InsertReplaceEdit {
        var newText: String
        var insert: CDLSPSourceFileRange
        var replace: CDLSPSourceFileRange
    }
    
    var label: String
    var kind: CompletionItemKind?
    var tags: [CompletionItemTag]?
    var detail: String?
    var documentation: (String?, CDLSPMarkupContent?)?
    var deprecated: Bool? // deprecated
    var preselect: Bool?
    var sortText: String?
    var filterText: String?
    var insertText: String?
    var insertTextFormat: InsertTextFormat?
    var insertTextMode: InsertTextMode?
    var textEdit: (CDLSPTextEdit?, InsertReplaceEdit?)?
    var additionalTextEdits: [CDLSPTextEdit]?
    var commitCharacters: [String]?
    var command: Command? // will not implement
    var data: Data? // will not implement
    
}


struct CDLSPMarkupContent {
    
    enum MarkupKind: String {
        case plainText = "plainText"
        case markdown = "markdown"
    }
    
    var kind: MarkupKind
    var value: String
    
}
