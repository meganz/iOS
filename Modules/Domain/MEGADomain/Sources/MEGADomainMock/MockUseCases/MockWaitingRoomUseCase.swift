import MEGADomain

public final class MockWaitingRoomUseCase: WaitingRoomUseCaseProtocol {
    private let myUserName: String
    
    public init(myUserName: String = "") {
        self.myUserName = myUserName
    }
    
    public func userName() -> String {
        myUserName
    }
}
