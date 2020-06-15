import Foundation



indirect enum MarkedString {
    case text(tag: [String], text: String, child: MarkedString)
    case end
    
    func attributedString(withStyleRegistration styleRegistration: [String: AttributedTextStyle]) -> NSAttributedString {
        switch self {
        case let .text(tag: tags, text: text, child: child):
            let styles = styleRegistration.compactMap { (key, value) -> AttributedTextStyle? in
                if tags.contains(key) { return value }
                return nil
            }
            
            let styler = AttributedTextStyle.composedStyler(from: styles)
            let nodeAttributedString = NSMutableAttributedString(string: text, attributes: styler(TextAttributes()))
            nodeAttributedString.append(child.attributedString(withStyleRegistration: styleRegistration))
            return nodeAttributedString
            
        case .end:
            return NSAttributedString()
        }
    }
}

func attributedText(from tagText: String, styleRegistration: [String: AttributedTextStyle]) -> NSAttributedString {
    let scanner = Scanner(string: tagText)
    scanner.charactersToBeSkipped = nil
    scanner.caseSensitive = true
    
    let taggedTextChain = scanTaggedText(scanner: scanner, tags: [])
    return taggedTextChain.attributedString(withStyleRegistration: styleRegistration)
}

func scanTaggedText(scanner: Scanner, tags: [String]) -> MarkedString {

    var text = scanner.scanTo("<") ?? ""
    if text.hasPrefix(">") == true {
        text = String(text.dropFirst())
    }

    guard var tag = scanner.scanTo(">") else {
        return .end
    }
    
    if tag.hasPrefix("<") == true {
        tag = String(tag.dropFirst())
    }
        
    if tag.hasPrefix("/") == true { // end of tag
        return MarkedString.text(tag: tags,
                               text: text,
                               child: scanTaggedText(scanner: scanner, tags: tags.dropLast()))
    } else {
        return MarkedString.text(tag: tags,
                               text: text,
                               child: scanTaggedText(scanner: scanner, tags: tags + [tag]))
    }
}
