import Foundation
import Combine

final class ScrollPositionCalculator {
    private var positionRecordDict = [PhotoScrollPosition?: CGRect]()
    private var viewPortSize = CGSize.zero
    private var offsetRecord: (first: CGFloat?, last: CGFloat?) = (nil, nil)
    private var tappedPosition: PhotoScrollPosition?
    
    private var visiblePositionDict = [PhotoScrollPosition?: Bool]()
    
    private let offsetSubject = PassthroughSubject<CGFloat, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        offsetSubject
            .dropFirst()
            .throttle(for: .seconds(0.15), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in
                self?.offsetRecord.last = $0
                if self?.offsetRecord.first == nil {
                    self?.offsetRecord.first = $0
                }
            }
            .store(in: &subscriptions)
    }
    
    func recordFrame<T: PhotosChronologicalCategory>(_ frame: CGRect, for category: T, inViewPort size: CGSize) {
        positionRecordDict[category.position] = frame
        viewPortSize = size
    }
    
    func recordContentOffset(_ offset: CGFloat) {
        offsetSubject.send(offset)
    }
    
    func recordTappedPosition(_ position: PhotoScrollPosition?) {
        tappedPosition = position
    }
    
    func recordAppearedPosition(_ position: PhotoScrollPosition?) {
        visiblePositionDict[position] = true
    }
    
    func recordDisappearedPosition(_ position: PhotoScrollPosition?) {
        visiblePositionDict[position] = nil
        positionRecordDict[position] = nil
    }
    
    func calculateScrollPosition(_ position: inout PhotoScrollPosition?) {
        guard tappedPosition == nil else {
            // Tapped position is the first priority
            position = tappedPosition
            tappedPosition = nil
            return
        }
                
        guard case var (.some(firstOffset), .some(lastOffset)) = offsetRecord else {
            // Don't update position when we have not recorded any offset changes
            return
        }
        
        firstOffset = max(firstOffset, 0) // Ignore negative offset
        lastOffset = max(lastOffset, 0) // Ignore negative offset
        
        guard abs(lastOffset - firstOffset) > 16 else {
            // Don't update position when the scroll offset change is neglectable
            return
        }
        
        guard lastOffset > 24 else {
            // When it closes to top, we prefer top over center
            position = .top
            return
        }

        let viewPortCenter = viewPortSize.height / 2
        var scrolledPosition: PhotoScrollPosition?
        var shortestDistanceToViewPortCenter = CGFloat.zero
        
        var samplePosition: PhotoScrollPosition?
        for positionKey in visiblePositionDict.keys {
            guard let frame = positionRecordDict[positionKey] else {
                continue
            }
            
            MEGALogDebug("[Photos] calculating \(String(describing: positionKey?.date)) and frame \(frame)")
            
            if samplePosition == nil {
                samplePosition = positionKey
                scrolledPosition = positionKey
                shortestDistanceToViewPortCenter = abs(viewPortCenter - frame.midY)
            }
            
            let distance = abs(viewPortCenter - frame.midY)
            if distance < shortestDistanceToViewPortCenter {
                shortestDistanceToViewPortCenter = distance
                scrolledPosition = positionKey
            }
        }
        
        if scrolledPosition != nil {
            position = scrolledPosition
        }
    }
}
