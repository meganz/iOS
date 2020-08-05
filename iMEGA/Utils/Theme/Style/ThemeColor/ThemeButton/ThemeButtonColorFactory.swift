import Foundation

protocol ButtonColorFactory {

    func normalColor() -> Color

    func disabledColor() -> Color

    func highlightedColor() -> Color
}
