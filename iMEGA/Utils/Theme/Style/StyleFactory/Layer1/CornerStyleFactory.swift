import Foundation

extension InterfaceStyle {

    var cornerStyleFactory: CornerStyleFactory {
        CornerStyleFactoryImpl()
    }
}

enum MEGACornerStyle {
    case round
}

protocol CornerStyleFactory {
    func cornerStyle(of cornerStyle: MEGACornerStyle) -> CornerStyle
}

private struct CornerStyleFactoryImpl: CornerStyleFactory {

    func cornerStyle(of cornerStyle: MEGACornerStyle) -> CornerStyle {
        switch cornerStyle {
        case .round: return CornerStyle(radius: 8)
        }
    }
}
