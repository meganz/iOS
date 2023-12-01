import SwiftUI

protocol CameraUploadBannerStatusViewPresenterProtocol {
    var title: String { get }
    var subheading: String { get }
    func textColor(for scheme: ColorScheme) -> Color
    func backgroundColor(for scheme: ColorScheme) -> Color
}

extension CameraUploadBannerStatusViewPresenterProtocol {
    func bottomBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .gray545458.opacity(0.3) : .gray3C3C43.opacity(0.65)
    }
}

struct CameraUploadBannerStatusViewPreviewEntity: CameraUploadBannerStatusViewPresenterProtocol, Hashable {
    
    let title: String
    let subheading: String
    let textColor: (ColorScheme) -> Color
    let backgroundColor: (ColorScheme) -> Color
    
    func textColor(for scheme: ColorScheme) -> Color {
        textColor(scheme)
    }
    
    func backgroundColor(for scheme: ColorScheme) -> Color {
        backgroundColor(scheme)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(subheading)
    }
    
    static func == (lhs: CameraUploadBannerStatusViewPreviewEntity, rhs: CameraUploadBannerStatusViewPreviewEntity) -> Bool {
        [lhs.title, lhs.subheading] == [rhs.title, rhs.subheading]
    }
}
