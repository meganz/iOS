import Foundation

enum EmptyMediaDiscoveryContentMenuAction: String, CaseIterable, Identifiable {
    case choosePhotoVideo
    case capturePhotoVideo
    case importFromFiles
    case scanDocument
    case newFolder
    case newTextFile
    
    var id: String { rawValue }
}
