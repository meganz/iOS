import Foundation

struct Color: Codable {
    typealias ColorValue = CGFloat

    let red: ColorValue
    let green: ColorValue
    let blue: ColorValue
    var alpha: ColorValue = 1
}

func uiColor(from colorProvider: ColorProviding) -> UIColor {
    return colorProvider.color
}

extension Color {
    static var white: Color { return Color(red: 1, green: 1, blue: 1) }
}

extension Color: ColorProviding {
    var color: UIColor { return UIColor(red: red, green: green, blue: blue, alpha: alpha) }
}
