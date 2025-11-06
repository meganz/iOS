import Combine
import Foundation

public final class PhotoScrollTracker {
    private var positionRecordDict = [PhotoScrollPosition?: CGRect]()
    private var viewPortSize = CGSize.zero
    private var offsetRecord: (first: CGFloat?, last: CGFloat?) = (nil, nil)
    private var tappedPosition: PhotoScrollPosition?
    
    private(set) var visiblePositions = [PhotoScrollPosition?: Bool]()
    
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
    
    func trackFrame(_ frame: CGRect, for position: PhotoScrollPosition?, inViewPort size: CGSize) {
        positionRecordDict[position] = frame
        viewPortSize = size
    }
    
    func trackContentOffset(_ offset: CGFloat) {
        offsetSubject.send(offset)
    }
    
    func trackTappedPosition(_ position: PhotoScrollPosition?) {
        tappedPosition = position
    }
    
    func trackAppearedPosition(_ position: PhotoScrollPosition?) {
        visiblePositions[position] = true
    }
    
    func trackDisappearedPosition(_ position: PhotoScrollPosition?) {
        visiblePositions[position] = nil
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
        
        firstOffset = max(firstOffset, CGFloat.zero) // Ignore negative offset
        lastOffset = max(lastOffset, CGFloat.zero) // Ignore negative offset
        
        guard abs(lastOffset - firstOffset) > CGFloat(16) else {
            // Don't update position when the scroll offset change is neglectable
            return
        }
        
        guard lastOffset > CGFloat(24) else {
            // When it closes to top, we prefer top over center
            position = .top
            return
        }

        let viewPortCenter = viewPortSize.height / CGFloat(2)
        var scrolledPosition: PhotoScrollPosition?
        var shortestDistanceToViewPortCenter = CGFloat.zero
        
        var samplePosition: PhotoScrollPosition?
        for positionKey in visiblePositions.keys {
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
