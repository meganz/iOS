import Foundation

protocol ButtonColorFactory {

    func normalColor() -> UIColor

    func disabledColor() -> UIColor

    func highlightedColor() -> UIColor
}
