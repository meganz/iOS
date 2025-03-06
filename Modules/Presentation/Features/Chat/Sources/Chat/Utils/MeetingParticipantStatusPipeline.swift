import Combine
import Foundation
import MEGADomain

public final class MeetingParticipantStatusPipeline {
    public struct HandlerCollectionType {
        public var addedHandlers = [HandleEntity]()
        public var removedHandlers = [HandleEntity]()
    }
    
    public let statusPublisher = PassthroughSubject<HandlerCollectionType, Never>()
    
    private var handlerCollectionType = HandlerCollectionType()
    private var timerSubscription: AnyCancellable?
    
    private let collectionDuration: TimeInterval
    private let resetCollectionDurationUpToCount: UInt
    
    private var resetCollectionDurationUpToCountCurrentValue = 0
    
    public init(collectionDuration: TimeInterval, resetCollectionDurationUpToCount: UInt) {
        self.collectionDuration = collectionDuration
        self.resetCollectionDurationUpToCount = resetCollectionDurationUpToCount
    }
    
    public func addParticipant(withHandle handle: HandleEntity) {
        if let index = handlerCollectionType.removedHandlers.firstIndex(of: handle) {
            handlerCollectionType.removedHandlers.remove(at: index)
            cancelTimerSubscriptionIfNeeded()
            return
        }
        
        resetCollectionDurationUpToCountCurrentValue += 1
        handlerCollectionType.addedHandlers.append(handle)
        
        resetTimerSubscriptionIfNeeded()
    }
    
    public func removeParticipant(withHandle handle: HandleEntity) {
        if let index = handlerCollectionType.addedHandlers.firstIndex(of: handle) {
            handlerCollectionType.addedHandlers.remove(at: index)
            cancelTimerSubscriptionIfNeeded()
            return
        }
        
        resetCollectionDurationUpToCountCurrentValue += 1
        handlerCollectionType.removedHandlers.append(handle)
        
        resetTimerSubscriptionIfNeeded()
    }
    
    private func resetTimerSubscriptionIfNeeded() {
        guard resetCollectionDurationUpToCountCurrentValue <= resetCollectionDurationUpToCount else { return }
        
        timerSubscription?.cancel()
        timerSubscription = Timer
            .publish(every: collectionDuration, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                
                self.statusPublisher.send(self.handlerCollectionType)
                
                self.resetCollectionDurationUpToCountCurrentValue = 0
                self.handlerCollectionType = HandlerCollectionType()
                self.timerSubscription?.cancel()
                self.timerSubscription = nil
            }
    }
    
    private func cancelTimerSubscriptionIfNeeded() {
        guard handlerCollectionType.addedHandlers.isEmpty && handlerCollectionType.removedHandlers.isEmpty else { return }
        
        timerSubscription?.cancel()
    }
}
