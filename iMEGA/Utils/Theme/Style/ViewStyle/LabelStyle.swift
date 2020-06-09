import UIKit

typealias LabelStyler = (UILabel) -> Void

enum LabelStyle {
    case headline
    case noteMain
    case noteSub

    var style: LabelStyler {
        switch self {
        case .headline: return headlineStyler
        case .noteMain: return noteMainStyler
        case .noteSub: return noteSubStyler
        }
    }
}

fileprivate let headlineStyler: (UILabel) -> Void = { label in
    TextStyle.headlineTextStyle.applied(on: label)
}

fileprivate let noteMainStyler: (UILabel) -> Void = { label in
    TextStyle.noteMainTextStyle.applied(on: label)
}

fileprivate let noteSubStyler: (UILabel) -> Void = { label in
    TextStyle.noteSubTextStyle.applied(on: label)
}
