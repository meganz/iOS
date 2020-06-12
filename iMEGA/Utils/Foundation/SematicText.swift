import Foundation

indirect enum SematicText {
    case node([AttributedTextStyle], String, SematicText)
    case leaf([AttributedTextStyle], String)

    func concat(_ other: SematicText) -> SematicText {
        switch self {
        case .leaf(let styles, let text):
            return .node(styles, text, other)
        case .node(let styles, let text, let child):
            return .node(styles, text, child.concat(other))
        }
    }

    static func + (lhs: SematicText, rhs: SematicText) -> SematicText {
        lhs.concat(rhs)
    }
}

extension SematicText {
    var attributedString: NSAttributedString {
        return attributedString(from: self)
    }

    private func attributedString(from sematicText: SematicText) -> NSAttributedString {
        switch sematicText {
        case .node(let styles, let text, let child):
            let styler = AttributedTextStyle.composedStyler(from: styles)
            let nodeAttributedString = NSMutableAttributedString(string: text, attributes: styler(TextAttributes()))
            nodeAttributedString.append(attributedString(from: child))
            return nodeAttributedString
        case .leaf(let styles, let text):
            let styler = AttributedTextStyle.composedStyler(from: styles)
            return NSAttributedString(string: text, attributes: styler(TextAttributes()))
        }
    }
}

extension SematicText {

    var string: String {
        return string(from: self)
    }

    private func string(from sematicText: SematicText) -> String {
        switch sematicText {
        case .node(_, let text, let child):
            return text + string(from: child)
        case .leaf(_, let text):
            return text
        }
    }
}

extension Optional where Wrapped == SematicText {

    func concat(_ other: SematicText?) -> SematicText? {
        switch other {
        case .none: return self
        case .some(let text):
            switch self {
            case .none: return text
            case .some(let myText): return myText + text
            }
        }
    }

    static func + (lhs: SematicText?, rhs: SematicText?) -> SematicText? {
        lhs.concat(rhs)
    }
}
