import Foundation

extension InterfaceStyle {

    var cornerStyleFactory: CornerStyleFactory {
        CornerStyleFactoryImpl()
    }
}

enum MEGACornerStyle {
    case round
    case ten
    case twelve
    case twoAndHalf
}

protocol CornerStyleFactory {
    func cornerStyle(of cornerStyle: MEGACornerStyle) -> CornerStyle
}

private struct CornerStyleFactoryImpl: CornerStyleFactory {

    func cornerStyle(of cornerStyle: MEGACornerStyle) -> CornerStyle {
        switch cornerStyle {
        case .round:    return CornerStyle(radius: 8)
        case .ten:      return CornerStyle(radius: 10)
        case .twelve:   return CornerStyle(radius: 12)
        case .twoAndHalf: return CornerStyle(radius: 2.5)
        }
    }
}
