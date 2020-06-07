import UIKit

typealias LabelStyler = (UILabel) -> Void

enum LabelStyle {
    case headline

    var style: LabelStyler {
        switch self {
        case .headline: return headlineStyler
        }
    }
}

fileprivate let headlineStyler: (UILabel) -> Void = { label in
    TextStyle.headlineTextStyle.applied(on: label)
}
