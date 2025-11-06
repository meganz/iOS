import Foundation

public struct PhotoCellVideoDurationViewModel {
    let isVideo: Bool
    let duration: String
    var scaleFactor: PhotoLibraryZoomState.ScaleFactor
    
    public init(isVideo: Bool, duration: String, scaleFactor: PhotoLibraryZoomState.ScaleFactor =  PhotoLibraryZoomState.defaultScaleFactor) {
        self.isVideo = isVideo
        self.duration = duration
        self.scaleFactor = scaleFactor
    }
    
    var shouldShowDuration: Bool {
        isVideo && scaleFactor != .thirteen && duration != ""
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
    
    private let durationYOffsetMapping: [PhotoLibraryZoomState.ScaleFactor: CGFloat] = [
        .one: -6, .three: -5, .five: -2, .thirteen: 0
    ]
    
    var durationYOffset: CGFloat {
        durationYOffsetMapping[scaleFactor] ?? -5
    }
}
