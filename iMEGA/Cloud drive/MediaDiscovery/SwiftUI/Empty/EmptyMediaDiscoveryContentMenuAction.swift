import Foundation

enum EmptyMediaDiscoveryContentMenuAction: String, CaseIterable, Identifiable {
    case choosePhotoVideo
    case capturePhotoVideo
    
    var id: String { rawValue }
}
