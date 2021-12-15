import Foundation

final class ScrollPositionCalculator {
    private var cellFrameDict = [PhotoScrollPosition: CGRect]()
    
    func calculateScrollPosition<T: PhotosChronologicalCategory>(with category: T, frame: CGRect, viewPortSize size: CGSize) -> PhotoScrollPosition {
        cellFrameDict[category.position] = frame
        
        let viewPortCenter = size.height / 2
        var scrollPosition = category.position
        var shortestDistanceToViewPortCenter = abs(viewPortCenter - frame.midY)
        for (positionId, frame) in cellFrameDict {
            let distance = abs(viewPortCenter - frame.midY)
            if distance < shortestDistanceToViewPortCenter {
                shortestDistanceToViewPortCenter = distance
                scrollPosition = positionId
            }
        }
        
        return scrollPosition
    }
}
