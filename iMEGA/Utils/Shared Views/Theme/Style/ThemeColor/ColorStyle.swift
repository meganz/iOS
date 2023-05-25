import Foundation

enum ColorStyleType: String, Codable {
    case foreground
    case background
    case tint
    case selectedTint
}

struct ColorStyle: Codable {
    let color: ThemeColor
    let type: ColorStyleType
}

extension ColorStyle {

    // MARK: - UILabel Applier

    @discardableResult
    func applied(on label: UILabel) -> UILabel {
        apply(style: self)(label)
    }

    // MARK: - UIButton Applier

    @discardableResult
    func applied(on button: UIButton, state: ButtonState) -> UIButton {
        apply(style: self, state: state)(button)
    }

    // MARK: - AttributedString Applier

    @discardableResult
    func applied(on attributes: TextAttributes) -> TextAttributes {
        apply(style: self)(attributes)
    }

    // MARK: - UITextField Applier

    @discardableResult
    func applied(on textField: UITextField) -> UITextField {
        apply(style: self)(textField)
    }

    // MARK: - UIPageControl Applier

    @discardableResult
    func applied(on pageControl: UIPageControl) -> UIPageControl {
        apply(style: self)(pageControl)
    }
}

private func apply(style: ColorStyle) -> (UILabel) -> UILabel {
    return { label in
        switch style.type {
        case .foreground: label.textColor = style.color.uiColor
        case .background: label.backgroundColor = style.color.uiColor
        default: break
        }
        return label
    }
}

private func apply(style: ColorStyle, state: ButtonState) -> (UIButton) -> UIButton {
    return { button in
        switch style.type {
        case .foreground:
            button.setTitleColor(style.color.uiColor, for: state.uiButtonState)
        default: break
        }
        return button
    }
}

private func apply(style: ColorStyle) -> (TextAttributes) -> TextAttributes {
    return { attributes in
        var copyAttributes = attributes
        switch style.type {
        case .foreground: copyAttributes[.foregroundColor] = style.color.uiColor
        case .background: copyAttributes[.backgroundColor] = style.color.uiColor
        default: break
        }
        return copyAttributes
    }
}

private func apply(style: ColorStyle) -> (UITextField) -> UITextField {
    return { textField in
        switch style.type {
        case .foreground: textField.textColor = style.color.uiColor
        case .background: textField.backgroundColor = style.color.uiColor
        default: break
        }
        return textField
    }
}

private func apply(style: ColorStyle) -> (UIPageControl) -> UIPageControl {
    return { pageControl in
        switch style.type {
        case .background: pageControl.backgroundColor = style.color.uiColor
        case .tint: pageControl.pageIndicatorTintColor = style.color.uiColor
        case .selectedTint: pageControl.currentPageIndicatorTintColor = style.color.uiColor
        default: break
        }
        return pageControl
    }
}
