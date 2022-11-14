import Foundation

final class PhotoCellVideoDurationViewModel {
    private var fontSizeMapping: [PhotoLibraryZoomState.ScaleFactor: CGFloat] = [
        .one : 16, .three : 12, .five : 8, .thirteen : 5
    ]
    
    func fontSize(with scaleFactor: PhotoLibraryZoomState.ScaleFactor) -> CGFloat {
        return fontSizeMapping[scaleFactor] ?? 12
    }
}
