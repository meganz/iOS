import Foundation

struct PhotoCellVideoDurationViewModel {
    let isVideo: Bool
    let duration: String
    var scaleFactor: PhotoLibraryZoomState.ScaleFactor = PhotoLibraryZoomState.defaultScaleFactor
    
    var shouldShowDuration: Bool {
        isVideo && scaleFactor != .thirteen
    }
    
    private let fontSizeMapping: [PhotoLibraryZoomState.ScaleFactor: CGFloat] = [
        .one : 16, .three : 12, .five : 8, .thirteen : 5
    ]
    
    var fontSize: CGFloat {
        return fontSizeMapping[scaleFactor] ?? 12
    }
}
