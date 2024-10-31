import Combine
import Foundation
import UIKit

final class PhotoZoomControlPositionTracker: ObservableObject {
    
    @Published private(set) var viewOffset: CGFloat
    
    private let offsetSubject = CurrentValueSubject<CGFloat, Never>(0)
    private let viewSpaceSubject = CurrentValueSubject<CGFloat, Never>(0)
    
    init(shouldTrackScrollOffsetPublisher: some Publisher<Bool, Never>,
         baseOffset: CGFloat) {
        
        viewOffset = baseOffset
        
        subscribeToScrollOffset(
            shouldTrackScrollOffsetPublisher: shouldTrackScrollOffsetPublisher,
            baseOffset: baseOffset)
    }
    
    func trackContentOffset(_ offset: CGFloat) {
        offsetSubject.send(offset)
    }
    
    func update(viewSpace: CGFloat) {
        viewSpaceSubject.send(viewSpace)
    }
    
    /// Creates publisher subscription that monitors conditions of current scroll off set value, view space required to offset by and if the feature should track values.
    /// - Parameters:
    ///   - shouldTrackScrollOffsetPublisher: Publisher that emits if the scroll offset should track and return desired views offset. If this emits false, the emitted offset will lock to the baseOffset provided.
    ///   - baseOffset: The baseOffset to lock a given view to the top of scroll container.
    private func subscribeToScrollOffset(shouldTrackScrollOffsetPublisher: some Publisher<Bool, Never>, baseOffset: CGFloat) {
        
        shouldTrackScrollOffsetPublisher
            .removeDuplicates()
            .map { [weak self] shouldTrackOffset -> AnyPublisher<CGFloat, Never> in
                guard shouldTrackOffset, let self else {
                    return Just(baseOffset).eraseToAnyPublisher()
                }
                return offsetSubject
                    .combineLatest(viewSpaceSubject.removeDuplicates())
                    .map { scrollOffset, viewSpace -> CGFloat in
                        switch scrollOffset {
                        case ...baseOffset:
                            // If the current scroll offset, is below the base offset, then it is recommend to to lock the views offset to max allowed offset (base + viewSpace)
                            return baseOffset + viewSpace
                        case baseOffset...(baseOffset + viewSpace):
                            // If the scroll offset, is between the baseOffset and the given viewSpace height, then it is recommend to track the scroll and move/offset the view in this space.
                            return -scrollOffset + viewSpace
                        default:
                            // If the scroll offset, is greater than the baseOffset + viewSpace, then it is recommend to to lock the views offset to baseOffset (lock to the top of the scroll view container)
                            return baseOffset
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewOffset)
    }
}
