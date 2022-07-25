import Foundation

final class FeatureToggle: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    @Published var isEnabled: Bool
    
    init(name: String, isEnabled: Bool) {
        self.name = name
        self.isEnabled = isEnabled
    }
}

extension FeatureToggle {
    static let removeHomeImage = FeatureToggle(name: "Remove Home Image", isEnabled: false)
    static let slideShow = FeatureToggle(name: "Slide Show", isEnabled: false)
    static let contextMenuOnCameraUploadExplorer = FeatureToggle(name: "Context Menu On CameraUpload Explorer", isEnabled: false)
    
    static var list: [FeatureToggle] = [
        removeHomeImage,
        slideShow,
        contextMenuOnCameraUploadExplorer
    ]
}
