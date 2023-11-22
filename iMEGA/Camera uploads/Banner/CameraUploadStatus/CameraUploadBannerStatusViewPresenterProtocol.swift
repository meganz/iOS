import SwiftUI

protocol CameraUploadBannerStatusViewPresenterProtocol {
    var title: String { get }
    var subheading: String { get }
    var textColor: AnyShapeStyle { get }
    var backgroundColor: AnyShapeStyle { get }
}

struct CameraUploadBannerStatusViewPreviewEntity: CameraUploadBannerStatusViewPresenterProtocol, Hashable {
    
    let title: String
    let subheading: String
    let textColor: AnyShapeStyle
    let backgroundColor: AnyShapeStyle

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(subheading)
    }
    
    static func == (lhs: CameraUploadBannerStatusViewPreviewEntity, rhs: CameraUploadBannerStatusViewPreviewEntity) -> Bool {
        [lhs.title, lhs.subheading] == [rhs.title, rhs.subheading]
    }
}
