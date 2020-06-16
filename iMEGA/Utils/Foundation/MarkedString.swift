import Foundation

enum MarkedStringParser {

    static func parseAttributedString(from text: String,
                                      withStyleRegistration styleRegistration: [String: AttributedTextStyle])
        -> NSAttributedString {

        let scanner = parserScanner(with: text)
        let taggedTextChain = scanMarkedText(scanner: scanner, tags: [])
        let attributedString = taggedTextChain.attributedString(withStyleRegistration: styleRegistration)
        return attributedString
    }
}

fileprivate func parserScanner(with text: String) -> Scanner {
    let scanner = Scanner(string: text)
    scanner.charactersToBeSkipped = nil
    scanner.caseSensitive = true
    return scanner
}

fileprivate indirect enum MarkedString {
    case text(tag: [String], text: String, child: MarkedString)
    case end
}

extension MarkedString {
    
    func attributedString(withStyleRegistration styleRegistration: [String: AttributedTextStyle]) -> NSAttributedString {
        switch self {
        case let .text(tag: tags, text: text, child: child):
            if text.isEmpty {
                return child.attributedString(withStyleRegistration: styleRegistration)
            }

            let styles = tags.compactMap { styleRegistration[$0] }
            
            let styler = AttributedTextStyle.composedStyler(from: styles)
            let nodeAttributedString = NSMutableAttributedString(string: text, attributes: styler(TextAttributes()))
            nodeAttributedString.append(child.attributedString(withStyleRegistration: styleRegistration))
            return nodeAttributedString
            
        case .end:
            return NSAttributedString()
        }
    }
}

fileprivate func scanMarkedText(scanner: Scanner, tags: [String]) -> MarkedString {

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
        
    if tag.hasPrefix("/") == true {
        return MarkedString.text(tag: tags,
                                 text: text,
                                 child: scanMarkedText(scanner: scanner, tags: tags.dropLast()))
    } else {
        return MarkedString.text(tag: tags,
                                 text: text,
                                 child: scanMarkedText(scanner: scanner, tags: tags + [tag]))
    }
}
