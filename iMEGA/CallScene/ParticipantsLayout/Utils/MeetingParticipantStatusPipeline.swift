import Combine
import Foundation
import MEGADomain

final class MeetingParticipantStatusPipeline {
    struct HandlerCollectionType {
        var addedHandlers = [HandleEntity]()
        var removedHandlers = [HandleEntity]()
    }
    
    let statusPublisher = PassthroughSubject<HandlerCollectionType, Never>()
    
    private var handlerCollectionType = HandlerCollectionType()
    private var timerSubscription: AnyCancellable?
    
    private let collectionDuration: TimeInterval
    private let resetCollectionDurationUptoCount: UInt
    
    private var resetCollectionDurationUptoCountCurrentValue = 0
    
    init(collectionDuration: TimeInterval, resetCollectionDurationUptoCount: UInt) {
        self.collectionDuration = collectionDuration
        self.resetCollectionDurationUptoCount = resetCollectionDurationUptoCount
    }
    
    func addParticipant(withHandle handle: HandleEntity) {
        if let index = handlerCollectionType.removedHandlers.firstIndex(of: handle) {
            handlerCollectionType.removedHandlers.remove(at: index)
            cancelTimerSubscriptionIfNeeded()
            return
        }
        
        resetCollectionDurationUptoCountCurrentValue += 1
        handlerCollectionType.addedHandlers.append(handle)
        
        resetTimerSubscriptionIfNeeded()
    }
    
    func removeParticipant(withHandle handle: HandleEntity) {
        if let index = handlerCollectionType.addedHandlers.firstIndex(of: handle) {
            handlerCollectionType.addedHandlers.remove(at: index)
            cancelTimerSubscriptionIfNeeded()
            return
        }
        
        resetCollectionDurationUptoCountCurrentValue += 1
        handlerCollectionType.removedHandlers.append(handle)
        
        resetTimerSubscriptionIfNeeded()
    }
    
    private func resetTimerSubscriptionIfNeeded() {
        guard resetCollectionDurationUptoCountCurrentValue <= resetCollectionDurationUptoCount else { return }
        
        timerSubscription?.cancel()
        timerSubscription = Timer
            .publish(every: collectionDuration, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.statusPublisher.send(self.handlerCollectionType)
                
                self.resetCollectionDurationUptoCountCurrentValue = 0
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
