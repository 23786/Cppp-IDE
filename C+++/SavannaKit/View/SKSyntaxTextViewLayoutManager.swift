//
//  SyntaxTextViewLayoutManager.swift
//  SavannaKit iOS
//
//  Created by Louis D'hauwe on 09/03/2018.
//  Copyright © 2018 Silver Fox. All rights reserved.
//

import Cocoa

public enum SKEditorPlaceholderState {
	case active
	case inactive
}

public extension NSAttributedString.Key {
	
    static let editorPlaceholder = NSAttributedString.Key("editorPlaceholder")
    
    static let foldedCode = NSAttributedString.Key("foldedCode")
    
    static let errorCode = NSAttributedString.Key("errorCode")

}

class SKSyntaxTextViewLayoutManager: NSLayoutManager, CDLineRangeCacheable {
    
    var string: NSString {
        return self.attributedString().string as NSString
    }
    
    var lineRangeCache = CDLineRangeCache()
    
	
	override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {

        guard let context = NSGraphicsContext.current else {
            return
        }
		
		let range = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
		
		var placeholders = [(CGRect, SKEditorPlaceholderState)]()
		
		textStorage?.enumerateAttribute(.editorPlaceholder, in: range, options: [], using: { (value, range, stop) in
			
			if let state = value as? SKEditorPlaceholderState {
				
				// the color set above
				let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
				let container = self.textContainer(forGlyphAt: glyphRange.location, effectiveRange: nil)
				
				let rect = self.boundingRect(forGlyphRange: glyphRange, in: container ?? NSTextContainer())
				
				placeholders.append((rect, state))
				
			}
			
		})

        context.saveGraphicsState()
        context.cgContext.translateBy(x: origin.x, y: origin.y)
		
		for (rect, state) in placeholders {
			
			// UIBezierPath with rounded
			
			let color: Color
			
			switch state {
			case .active:
				color = Color.textColor.withAlphaComponent(0.8)
			case .inactive:
				color = .darkGray
			}

			color.setFill()
			
			let radius: CGFloat = 4.0

            let path = BezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
			
			path.fill()
			
		}

        context.restoreGraphicsState()

		super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)

	}
    
    override func processEditing(for textStorage: NSTextStorage, edited editMask: NSTextStorageEditActions, range newCharRange: NSRange, changeInLength delta: Int, invalidatedRange invalidatedCharRange: NSRange) {
        
        if editMask.contains(.editedCharacters) {
            self.invalidateLineRanges(in: newCharRange, changeInLength: delta)
        }
        
        super.processEditing(for: textStorage, edited: editMask, range: newCharRange, changeInLength: delta, invalidatedRange: invalidatedCharRange)
    }
	
}
