import Foundation

final class PhotoCellVideoDurationViewModel {
    private var fontSizeMapping: [Int: CGFloat] = [1:16,3:12,5:8]
    
    func fontSize(with scaleFactor: Int) -> CGFloat {
        return fontSizeMapping[scaleFactor] ?? 12
    }
}
