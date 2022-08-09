import Foundation

protocol ButtonColorFactory {

    func normalColor() -> ThemeColor

    func disabledColor() -> ThemeColor

    func highlightedColor() -> ThemeColor
}
