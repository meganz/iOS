import Foundation

enum MarkedStringParser {

    static func parseAttributedString(from text: String, withStyleMarks styleMarks: [String: AttributedTextStyle], attributedTextStyleFactory: some AttributedTextStyleFactory) -> NSAttributedString {
        let scanner = textParsingScanner(with: text)
        let markedStringChain = scanMarkedText(scanner: scanner, tags: [])
        return markedStringChain.attributedString(withStyleMarks: styleMarks, attributedTextStyleFactory: attributedTextStyleFactory)
    }

    // MARK: - Privates

    private static func textParsingScanner(with text: String) -> Scanner {
        let scanner = Scanner(string: text)
        scanner.charactersToBeSkipped = nil
        scanner.caseSensitive = true
        return scanner
    }

    private static func scanMarkedText(scanner: Scanner, tags: [String]) -> MarkedString {

        var text = scanner.scanTo("<") ?? ""
        if text.hasPrefix(">") {
            text = String(text.dropFirst())
        }

        guard var tag = scanner.scanTo(">") else {
            if text.isEmpty { return .end } //
            return MarkedString.text(tag: tags, text: text, child: scanMarkedText(scanner: scanner, tags: tags))
        }

        if tag.hasPrefix("<") {
            tag = String(tag.dropFirst())
        }

        if tag.hasPrefix("/") {
            if text.isEmpty { return scanMarkedText(scanner: scanner, tags: tags.dropLast()) }
            return MarkedString.text(tag: tags, text: text, child: scanMarkedText(scanner: scanner, tags: tags.dropLast()))
        } else {
            if text.isEmpty { return scanMarkedText(scanner: scanner, tags: tags + [tag]) }
            return MarkedString.text(tag: tags, text: text, child: scanMarkedText(scanner: scanner, tags: tags + [tag]))
        }
    }
}
