import Foundation

final class ScrollPositionCalculator {
    private var cellFrameDict = [PhotoScrollPosition?: CGRect]()
    private var viewPortSize = CGSize.zero
    private var contentOffset = CGFloat.zero
    
    func recordFrame<T: PhotosChronologicalCategory>(_ frame: CGRect, for category: T, inViewPort size: CGSize) {
        cellFrameDict[category.position] = frame
        viewPortSize = size
    }
    
    func recordContentOffset(_ offset: CGFloat) {
        contentOffset = offset
    }
    
    func calculateScrollPosition(_ position: inout PhotoScrollPosition?) {
        guard let first = cellFrameDict.first else {
            updatePosition(&position, to: nil)
            return
        }
        
        guard contentOffset > 1 else {
            updatePosition(&position, to: nil)
            return
        }
        
        let viewPortCenter = viewPortSize.height / 2
        var scrollPosition = first.key
        var shortestDistanceToViewPortCenter = abs(viewPortCenter - first.value.midY)
        for (positionId, frame) in cellFrameDict {
            let distance = abs(viewPortCenter - frame.midY)
            if distance < shortestDistanceToViewPortCenter {
                shortestDistanceToViewPortCenter = distance
                scrollPosition = positionId
            }
        }
        
        updatePosition(&position, to: scrollPosition)
    }
    
    private func updatePosition(_ position: inout PhotoScrollPosition?, to calculatedPosition: PhotoScrollPosition?) {
        position = calculatedPosition
    }
}
