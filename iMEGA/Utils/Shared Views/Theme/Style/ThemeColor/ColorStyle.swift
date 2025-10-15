import Foundation

enum ColorStyleType: String, Codable {
    case foreground
    case background
    case tint
    case selectedTint
}

struct ColorStyle {
    let color: UIColor
    let type: ColorStyleType
}

extension ColorStyle {
    
    // MARK: - UILabel Applier
    
    @discardableResult
    @MainActor
    func applied(on label: UILabel) -> UILabel {
        apply(style: self)(label)
    }
    
    // MARK: - UIButton Applier
    
    @discardableResult
    @MainActor
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
    @MainActor
    func applied(on textField: UITextField) -> UITextField {
        apply(style: self)(textField)
    }
    
    // MARK: - UIPageControl Applier
    
    @discardableResult
    @MainActor
    func applied(on pageControl: UIPageControl) -> UIPageControl {
        apply(style: self)(pageControl)
    }
}

@MainActor
private func apply(style: ColorStyle) -> (UILabel) -> UILabel {
    return { label in
        switch style.type {
        case .foreground: label.textColor = style.color
        case .background: label.backgroundColor = style.color
        default: break
        }
        return label
    }
}

@MainActor
private func apply(style: ColorStyle, state: ButtonState) -> (UIButton) -> UIButton {
    return { button in
        switch style.type {
        case .foreground:
            button.setTitleColor(style.color, for: state.uiButtonState)
        default: break
        }
        return button
    }
}

private func apply(style: ColorStyle) -> (TextAttributes) -> TextAttributes {
    return { attributes in
        var copyAttributes = attributes
        switch style.type {
        case .foreground: copyAttributes[.foregroundColor] = style.color
        case .background: copyAttributes[.backgroundColor] = style.color
        default: break
        }
        return copyAttributes
    }
}

@MainActor
private func apply(style: ColorStyle) -> (UITextField) -> UITextField {
    return { textField in
        switch style.type {
        case .foreground: textField.textColor = style.color
        case .background: textField.backgroundColor = style.color
        default: break
        }
        return textField
    }
}

@MainActor
private func apply(style: ColorStyle) -> (UIPageControl) -> UIPageControl {
    return { pageControl in
        switch style.type {
        case .background: pageControl.backgroundColor = style.color
        case .tint: pageControl.pageIndicatorTintColor = style.color
        case .selectedTint: pageControl.currentPageIndicatorTintColor = style.color
        default: break
        }
        return pageControl
    }
}

extension UIColor {
    
    var asTextColorStyle: ColorStyle {
        ColorStyle(color: self, type: .foreground)
    }
    
    var asBackgroundColorStyle: ColorStyle {
        ColorStyle(color: self, type: .background)
    }
    
    var asTintColorStyle: ColorStyle {
        ColorStyle(color: self, type: .tint)
    }
    
    var asSelectedTintColorStyle: ColorStyle {
        ColorStyle(color: self, type: .selectedTint)
    }
}
