import MEGADesignToken
import SwiftUI

protocol CameraUploadBannerStatusViewPresenterProtocol {
    var title: String { get }
    var subheading: AttributedString { get }
    func textColor(for scheme: ColorScheme) -> Color
    func backgroundColor(for scheme: ColorScheme) -> Color
}

extension CameraUploadBannerStatusViewPresenterProtocol {
    func bottomBorder(for scheme: ColorScheme) -> Color {
        if CameraUploadBannerStatusViewStates.isDesignTokenEnabled {
            return TokenColors.Border.subtle.swiftUI
        }

        return scheme == .dark 
            ? UIColor.gray545458.swiftUI.opacity(0.3)
            : UIColor.gray3C3C43.swiftUI.opacity(0.65)
    }
}

struct CameraUploadBannerStatusViewPreviewEntity: CameraUploadBannerStatusViewPresenterProtocol, Hashable {
    
    let title: String
    let subheading: AttributedString
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
        [
            lhs.title == rhs.title,
            lhs.subheading == rhs.subheading
        ].allSatisfy { $0 }
    }
}
