//
//  SKSyntaxTextView.swift
//  SavannaKit
//
//  Created by Louis D'hauwe on 23/01/2017.
//  Copyright © 2017 Silver Fox. All rights reserved.
//

import Cocoa

protocol SKSyntaxTextViewDelegate: class {
	
	func didChangeText(_ syntaxTextView: SKSyntaxTextView)

	func didChangeSelectedRange(_ syntaxTextView: SKSyntaxTextView, selectedRange: NSRange)
	
	func textViewDidBeginEditing(_ syntaxTextView: SKSyntaxTextView)
	
	func lexerForSource(_ source: String) -> SKLexer
    
    func didScroll(_ syntaxTextView: SKSyntaxTextView, to: NSPoint)
    
    func didClickLineNumber(atLine: Int, button: CDCodeEditorLineNumberViewButton)
	
}

// Provide default empty implementations of methods that are optional.
extension SKSyntaxTextViewDelegate {
    
    func didChangeText(_ syntaxTextView: SKSyntaxTextView) { }
	
    func didChangeSelectedRange(_ syntaxTextView: SKSyntaxTextView, selectedRange: NSRange) { }
	
    func textViewDidBeginEditing(_ syntaxTextView: SKSyntaxTextView) { }
    
    func didScroll(_ syntaxTextView: SKSyntaxTextView, to: NSPoint) { }
    
    func didClickLineNumber(atLine: Int, button: CDCodeEditorLineNumberViewButton) { }
    
}

struct SKThemeInfo {
	
	let theme: SKSyntaxColorTheme
	
	/// Width of a space character in the theme's font.
	/// Useful for calculating tab indent size.
	let spaceWidth: CGFloat
	
}

class SKSyntaxTextView: View {

	var previousSelectedRange: NSRange?
	
	private var textViewSelectedRangeObserver: NSKeyValueObservation?

	let textView: SKInnerTextView
    
    var lineNumberView: CDCodeEditorLineNumberView?
    
    var isUsingLSP: Bool = true
    
    var lastEditTime: Date?
	
	public var contentTextView: TextView {
		return textView
	}
	
	public weak var delegate: SKSyntaxTextViewDelegate? {
		didSet {
			didUpdateText()
		}
	}
	
	var ignoreSelectionChange = false
    
	let wrapperView = SKTextViewWrapperView()
    
    var isChangingDocument = false
	
	public var tintColor: NSColor! {
		set {
			textView.tintColor = newValue
		}
		get {
			return textView.tintColor
		}
	}
    
    public override init(frame: CGRect) {
        textView = SKSyntaxTextView.createInnerTextView()
        super.init(frame: frame)
        lineNumberView = self.createLineNumberView()
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        textView = SKSyntaxTextView.createInnerTextView()
        NotificationCenter.default.addObserver(textView, selector: #selector(SKInnerTextView.receivedCompletion(_:)), name: NSNotification.Name("C+++_Received_Code_Completion_Data"), object: nil)
        super.init(coder: aDecoder)
        lineNumberView = self.createLineNumberView()
        setup()
    }
	
    private static func createInnerTextView() -> SKInnerTextView {
        
        let textStorage = NSTextStorage()
        let layoutManager = SKSyntaxTextViewLayoutManager()
        
        let containerSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
		
        let textContainer = NSTextContainer(size: containerSize)
        
        textContainer.widthTracksTextView = true
		
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        return SKInnerTextView(frame: .zero, textContainer: textContainer)
        
    }
    
    private func createLineNumberView() -> CDCodeEditorLineNumberView {
        return CDCodeEditorLineNumberView(frame: NSMakeRect(0, 0, 55, 0), textView: self.textView)
    }

    let scrollView = CDScrollView()
    let lineNumberScrollView = CDScrollView()
	
	private func setup() {
    
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        
        for scrollView in [scrollView, lineNumberScrollView] {
            
            scrollView.drawsBackground = false
            scrollView.scrollDelegate = self
            
            scrollView.contentView.backgroundColor = .clear
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            
            scrollView.scrollerKnobStyle = .light
            scrollView.borderType = .noBorder
            
            addSubview(scrollView)
            
        }

        addSubview(wrapperView)

        
        scrollView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 55.0).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        
        wrapperView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        wrapperView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        wrapperView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        wrapperView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        
        
        lineNumberScrollView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        lineNumberScrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        lineNumberScrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        lineNumberScrollView.widthAnchor.constraint(equalToConstant: 55.0).isActive = true
        lineNumberScrollView.documentView = lineNumberView
        
        lineNumberScrollView.drawsBackground = true
        lineNumberScrollView.backgroundColor = .textBackgroundColor
        let view = CDFlippedView(frame: NSMakeRect(0.0, 0.0, 55.0, 0.0))
        lineNumberScrollView.documentView = view
        view.addSubview(lineNumberView!)
        lineNumberView?.frame.origin = NSPoint.zero
        lineNumberView?.delegate = self
        lineNumberView?.widthAnchor.constraint(equalToConstant: 55.0).isActive = true
        lineNumberView?.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        lineNumberView?.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        lineNumberView?.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        lineNumberView?.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        // lineNumberView?.autoresizingMask = [.maxXMargin, .minXMargin, .maxYMargin, .minYMargin, .height, .width]
        // lineNumberView?.superview!.autoresizingMask = [.maxXMargin, .minXMargin, .maxYMargin, .minYMargin]
        lineNumberScrollView.hasVerticalScroller = false
        lineNumberScrollView.hasHorizontalScroller = false
        lineNumberScrollView.identifier = NSUserInterfaceItemIdentifier(rawValue: "lineNumberViewScrollView")
        
        
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.backgroundColor = .clear
        scrollView.identifier = NSUserInterfaceItemIdentifier(rawValue: "textViewScrollView")
        
        scrollView.documentView = textView
        scrollView.contentView.postsBoundsChangedNotifications = true
        
        textView.minSize = NSSize(width: 0.0, height: self.bounds.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width, .height]
        textView.isEditable = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.needsDisplay = true
        textView.backgroundColor = .textBackgroundColor
        textView.drawsBackground = true
        
        textView.textContainer?.containerSize = NSSize(width: self.bounds.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
//		textView.layerContentsRedrawPolicy = .beforeViewResize
        
        wrapperView.textView = textView
    
		textView.innerDelegate = self
		textView.delegate = self
        textView.lineNumberView = lineNumberView
		
		textView.text = ""

	}
	
	open override func viewDidMoveToSuperview() {
		super.viewDidMoveToSuperview()
	
	}

	// MARK: -
	
	@IBInspectable
	public var text: String {
		get {
            return textView.string
		}
        set {
            textView.layer?.isOpaque = true
            textView.string = newValue
            self.didUpdateText()
		}
	}
	
	// MARK: -
	
	public func insertText(_ text: String) {
		
		if shouldChangeText(insertingText: text) {
			
            contentTextView.insertText(text, replacementRange: contentTextView.selectedRange)
			
		}

	}

	public var theme: SKSyntaxColorTheme? {
		didSet {
			
			guard let theme = theme else {
				return
			}
			
			cachedThemeInfo = nil
            textView.backgroundColor = theme.backgroundColor
            textView.theme = theme
			textView.font = theme.font
			
			didUpdateText()
		}
	}
	
	var cachedThemeInfo: SKThemeInfo?
	
	var themeInfo: SKThemeInfo? {
		
		if let cached = cachedThemeInfo {
			return cached
		}
		
		guard let theme = theme else {
			return nil
		}
		
		let spaceAttrString = NSAttributedString(string: " ", attributes: [.font: theme.font])
		let spaceWidth = spaceAttrString.size().width
		
		let info = SKThemeInfo(theme: theme, spaceWidth: spaceWidth)
		
		cachedThemeInfo = info
		
		return info
	}
	
	var cachedTokens: [SKCachedToken]?
	
	func invalidateCachedTokens() {
		cachedTokens = nil
	}
	
	func colorTextView(lexerForSource: (String) -> SKLexer) {
		
		guard let source = textView.text else {
			return
		}
		
		let textStorage = textView.textStorage!
		
		let tokens: [SKToken]
		
		if let cachedTokens = cachedTokens {
			
			updateAttributes(textStorage: textStorage, cachedTokens: cachedTokens, source: source)
			
		} else {
			
			guard let theme = self.theme else {
				return
			}
			
			guard let themeInfo = self.themeInfo else {
				return
			}
			
			textView.font = theme.font

			let lexer = lexerForSource(source)
			tokens = lexer.getSavannaTokens(input: source)
			
			let cachedTokens: [SKCachedToken] = tokens.map {
				
				let nsRange = source.nsRange(fromRange: $0.range)
				return SKCachedToken(token: $0, nsRange: nsRange)
			}

			self.cachedTokens = cachedTokens
			
			createAttributes(theme: theme, themeInfo: themeInfo, textStorage: textStorage, cachedTokens: cachedTokens, source: source)
			
		}
		
	}

	func updateAttributes(textStorage: NSTextStorage, cachedTokens: [SKCachedToken], source: String) {

		let selectedRange = textView.selectedRange
		
		let fullRange = NSRange(location: 0, length: (source as NSString).length)
		
		var rangesToUpdate = [(NSRange, SKEditorPlaceholderState)]()
		
		textStorage.enumerateAttribute(.editorPlaceholder, in: fullRange, options: []) { (value, range, stop) in
			
			if let state = value as? SKEditorPlaceholderState {
				
				var newState: SKEditorPlaceholderState = .inactive
				
				if isEditorPlaceholderSelected(selectedRange: selectedRange, tokenRange: range) {
					newState = .active
				}
				
				if newState != state {					
					rangesToUpdate.append((range, newState))
				}
				
			}
		
		}
		
		var didBeginEditing = false
		
		if !rangesToUpdate.isEmpty {
			textStorage.beginEditing()
			didBeginEditing = true
		}
		
		for (range, state) in rangesToUpdate {
			
			var attr = [NSAttributedString.Key: Any]()
			attr[.editorPlaceholder] = state

			textStorage.addAttributes(attr, range: range)

		}
		
		if didBeginEditing {
			textStorage.endEditing()
		}

	}
	
	func createAttributes(theme: SKSyntaxColorTheme, themeInfo: SKThemeInfo, textStorage: NSTextStorage, cachedTokens: [SKCachedToken], source: String) {
		
		textStorage.beginEditing()

		var attributes = [NSAttributedString.Key: Any]()
		
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.paragraphSpacing = 2.0
		paragraphStyle.defaultTabInterval = themeInfo.spaceWidth * 4
		paragraphStyle.tabStops = []
		
		let wholeRange = NSRange(location: 0, length: (source as NSString).length)
		
		attributes[.paragraphStyle] = paragraphStyle
		
		for (attr, value) in theme.globalAttributes() {
			
			attributes[attr] = value

		}
		
		textStorage.setAttributes(attributes, range: wholeRange)
		
		let selectedRange = textView.selectedRange
		
		for cachedToken in cachedTokens {
			
			let token = cachedToken.token
			
			if token.isPlain {
				continue
			}
			
			let range = cachedToken.nsRange

			if token.isEditorPlaceholder {
				
				let startRange = NSRange(location: range.lowerBound, length: 2)
				let endRange = NSRange(location: range.upperBound - 2, length: 2)
				
				let contentRange = NSRange(location: range.lowerBound + 2, length: range.length - 4)
				
				var attr = [NSAttributedString.Key: Any]()
				
				var state: SKEditorPlaceholderState = .inactive
				
				if isEditorPlaceholderSelected(selectedRange: selectedRange, tokenRange: range) {
					state = .active
				}
				
				attr[.editorPlaceholder] = state
				
				textStorage.addAttributes(theme.attributes(for: token), range: contentRange)
				
				textStorage.addAttributes([.foregroundColor: Color.clear, .font: Font.systemFont(ofSize: 0.01)], range: startRange)
				textStorage.addAttributes([.foregroundColor: Color.clear, .font: Font.systemFont(ofSize: 0.01)], range: endRange)
				
				textStorage.addAttributes(attr, range: range)
				continue
			}
			
			textStorage.addAttributes(theme.attributes(for: token), range: range)
		}
		
		textStorage.endEditing()
		
	}
	
}

extension SKSyntaxTextView: CDScrollViewDelegate {
    
    func scrollView(_ scrollView: CDScrollView, didScrollTo point: NSPoint) {
        
        if scrollView.identifier?.rawValue == "textViewScrollView" {
            self.delegate?.didScroll(self, to: point)
            self.lineNumberScrollView.scrollWithoutInformingDelegate(self.lineNumberScrollView.contentView, to: point)
            self.lineNumberScrollView.reflectScrolledClipView(self.lineNumberScrollView.contentView)
        } else {
            self.scrollView.scroll(self.scrollView.contentView, to: point)
            self.scrollView.reflectScrolledClipView(self.scrollView.contentView)
        }
        
    }
    
}


extension SKSyntaxTextView: CDCodeEditorLineNumberViewDelegate {
    
    func didClickButton(atLine line: Int, button: CDCodeEditorLineNumberViewButton) {
        self.delegate?.didClickLineNumber(atLine: line, button: button)
    }
    
}
