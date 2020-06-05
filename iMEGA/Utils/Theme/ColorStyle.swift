import UIKit

struct StateColorStyle: Codable {
    let backgroundColor: StatefulColor
    var borderColor: StatefulColor? = nil
    var shadowColor: StatefulColor? = nil
}

struct ShadowStyle: Codable {
    typealias Offset = CGFloat
    
    let offset: Offset
}

struct StatefulColor: Codable {
    let normal: Color
    let highlighted: Color
    let disabled: Color
}

extension StatefulColor {
    static var greenButtonColor: StatefulColor { StatefulColor(normal: .backgroundEnabledPrimary,
                                                               highlighted: .backgroundHighlightedPrimary,
                                                               disabled: .backgroundDisabledPrimary) }
}

fileprivate func apply(style: StateColorStyle) -> (UILabel) -> UILabel {
    return { label in
        label.backgroundColor = style.backgroundColor.normal.uiColor
        label.layer.borderColor = style.borderColor?.normal.uiColor.cgColor
        label.shadowColor = style.shadowColor?.normal.uiColor
        return label
    }
}

//fileprivate func apply(style: ColorStyle) -> (UIButton) -> UIButton {
//    return { label in
//        label.textColor = uiColor(from: style.color)
//        label.font = uiFont(from: style.font)
//        label.backgroundColor = uiColor(from: style.backgroundColor)
//        return label
//    }
//}
