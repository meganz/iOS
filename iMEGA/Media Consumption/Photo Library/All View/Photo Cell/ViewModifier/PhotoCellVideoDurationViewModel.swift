import Foundation

struct PhotoCellVideoDurationViewModel {
    let isVideo: Bool
    let duration: String
    var scaleFactor: PhotoLibraryZoomState.ScaleFactor = PhotoLibraryZoomState.defaultScaleFactor
    
    var shouldShowDurationView: Bool {
        isVideo && scaleFactor != .thirteen
    }
    
    var shouldShowDurationDetail: Bool {
        isVideo && duration != ""
    }
    
    private let fontSizeMapping: [PhotoLibraryZoomState.ScaleFactor: CGFloat] = [
        .one: 16, .three: 12, .five: 8, .thirteen: 5
    ]
    
    var fontSize: CGFloat {
        return fontSizeMapping[scaleFactor] ?? 12
    }
    
    private let playIconSizeMapping: [PhotoLibraryZoomState.ScaleFactor: CGFloat] = [
        .one: 26, .three: 22, .five: 14, .thirteen: 10
    ]
    
    var iconSize: CGFloat {
        return playIconSizeMapping[scaleFactor] ?? 22
    }
    
    private let playIconOriginYMapping: [PhotoLibraryZoomState.ScaleFactor: CGFloat] = [
        .one: -6, .three: -5, .five: -2, .thirteen: 0
    ]
    
    var iconOriginY: CGFloat {
        return playIconOriginYMapping[scaleFactor] ?? -5
    }
}
