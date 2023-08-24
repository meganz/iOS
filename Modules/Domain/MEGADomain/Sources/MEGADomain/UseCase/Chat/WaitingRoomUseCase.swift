public protocol WaitingRoomUseCaseProtocol {
    func userName() -> String
}

public final class WaitingRoomUseCase<T: WaitingRoomRepositoryProtocol>: WaitingRoomUseCaseProtocol {
    private var waitingRoomRepo: T
    
    public init(waitingRoomRepo: T) {
        self.waitingRoomRepo = waitingRoomRepo
    }
    
    public func userName() -> String {
        waitingRoomRepo.userName()
    }
}
