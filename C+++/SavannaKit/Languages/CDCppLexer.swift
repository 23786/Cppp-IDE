//
//  CDCppLexer.swift
//  C+++
//
//  Created by Louis D'hauwe on 24/07/2018.
//  Copyright © 2018 Silver Fox. All rights reserved.
//

import Foundation

public enum SKSourceCodeTokenType {
    case plain
    case number
    case string
    case identifier
    case keyword
    case comment
    case preprocesscor
    case editorPlaceholder
}

protocol SKSourceCodeToken: SKToken {
    
    var type: SKSourceCodeTokenType { get }
    
}

extension SKSourceCodeToken {
    
    var isEditorPlaceholder: Bool {
        return type == .editorPlaceholder
    }
    
    var isPlain: Bool {
        return type == .plain
    }
    
}

struct SKSimpleSourceCodeToken: SKSourceCodeToken {
    
    let type: SKSourceCodeTokenType
    
    let range: Range<String.Index>
    
}

extension SKRegexLexer {
    public func regexGenerator(_ pattern: String, options: NSRegularExpression.Options = [], transformer: @escaping SKTokenTransformer) -> TokenGenerator? {
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            print("Regular Expression: \"\(pattern)\" not valid.")
            return nil
        }
        
        return .regex(SKRegexTokenGenerator(regularExpression: regex, tokenTransformer: transformer))
    }

}

class CDCppLexer: SKRegexLexer {
    
    public init() {
        
    }
    
    lazy var generators: [TokenGenerator] = {
        
        var generators = [TokenGenerator?]()
    
        generators.append(regexGenerator("\\b(0b[01']+)", tokenType: .number))
        generators.append(regexGenerator("(-?)\\b([\\d']+(\\.[\\d']*)?|\\.[\\d']+)(u|U|ll|l|LL|L|ul|UL|f|F|b|B)", tokenType: .number))
        generators.append(regexGenerator("(-?)(\\b0[xX][a-fA-F0-9']+|(\\b[\\d']+(\\.[\\d']*)?|\\.[\\d']+)([eE][-+]?[\\d']+)?)", tokenType: .number))
        
        generators.append(regexGenerator("(?<=\\.)[A-Za-z_]+\\w*", tokenType: .identifier))
        generators.append(regexGenerator("(?<=->)[A-Za-z_]+\\w*", tokenType: .identifier))
        generators.append(regexGenerator("(?<=::)[A-Za-z_]+\\w*", tokenType: .identifier))
        
        generators.append(regexGenerator("^\\s*#.*", options: [.anchorsMatchLines], tokenType: .preprocesscor))
        
        let keywords = "true false struct class int float while private char catch import module export virtual operator sizeof dynamic_cast typedef const_cast const for static_cast union namespace unsigned long volatile static protected bool template mutable if public friend do goto auto void enum else break extern using asm case typeid short reinterpret_cast default double register explicit signed typename try this switch continue inline delete alignof constexpr decltype noexcept static_assert thread_local restrict _Bool complex _Complex _Imaginary atomic_bool atomic_char atomic_schar atomic_uchar atomic_short atomic_ushort atomic_int atomic_uint atomic_long atomic_ulong atomic_llong atomic_ullong new throw return and or not".components(separatedBy: " ")
        
        generators.append(keywordGenerator(keywords, tokenType: .keyword))
        
        let stdlibIdentifiers = "std string cin cout cerr clog stdin stdout stderr stringstream istringstream ostringstream auto_ptr deque list queue stack vector map set bitset multiset multimap unordered_set unordered_map unordered_multiset unordered_multimap array shared_ptr abort abs acos asin atan2 atan calloc ceil cosh cos exit exp fabs floor fmod fprintf fputs free frexp fscanf isalnum isalpha iscntrl isdigit isgraph islower isprint ispunct isspace isupper isxdigit tolower toupper labs ldexp log10 log malloc realloc memchr memcmp memcpy memset modf pow printf putchar puts scanf sinh sin snprintf sprintf sqrt sscanf strcat strchr strcmp strcpy strcspn strlen strncat strncmp strncpy strpbrk strrchr strspn strstr tanh tan vfprintf vprintf vsprintf endl initializer_list unique_ptr priority_queue freopen pair getchar".components(separatedBy: " ")
        
        generators.append(keywordGenerator(stdlibIdentifiers, tokenType: .identifier))
        
        // Line comment
        generators.append(regexGenerator("//(.*)", tokenType: .comment))
        
        // Block comment
        generators.append(regexGenerator("(/\\*)(.*?)(\\*/)", options: [.dotMatchesLineSeparators], tokenType: .comment))

        // Single-line string literal
        generators.append(regexGenerator("\".*?\"", tokenType: .string))
        generators.append(regexGenerator("'.*?'", tokenType: .string))

        // Editor placeholder
        var editorPlaceholderPattern = "(<#)[^\"\\n]*?"
        editorPlaceholderPattern += "(#>)"
        generators.append(regexGenerator(editorPlaceholderPattern, tokenType: .editorPlaceholder))

        return generators.compactMap( { $0 })
    }()
    
    public func generators(source: String) -> [TokenGenerator] {
        return generators
    }
    
    public func regexGenerator(_ pattern: String, options: NSRegularExpression.Options = [], tokenType: SKSourceCodeTokenType) -> TokenGenerator? {
        
        return regexGenerator(pattern, options: options, transformer: { (range) -> SKToken in
            return SKSimpleSourceCodeToken(type: tokenType, range: range)
        })
    }
    
    public func keywordGenerator(_ words: [String], tokenType: SKSourceCodeTokenType) -> TokenGenerator {
        
        return .keywords(SKKeywordTokenGenerator(keywords: words, tokenTransformer: { (range) -> SKToken in
            return SKSimpleSourceCodeToken(type: tokenType, range: range)
        }))
    }
    
}
