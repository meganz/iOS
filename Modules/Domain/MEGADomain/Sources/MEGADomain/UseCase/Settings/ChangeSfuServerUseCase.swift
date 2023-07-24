import Foundation

public protocol ChangeSfuServerUseCaseProtocol {
    func changeSfuServer(to serverId: Int)
}

public struct ChangeSfuServerUseCase: ChangeSfuServerUseCaseProtocol {
    private var repository: any ChangeSfuServerRepositoryProtocol
    
    public init(repository: any ChangeSfuServerRepositoryProtocol) {
        self.repository = repository
    }
    
    public func changeSfuServer(to serverId: Int) {
        repository.changeSfuServer(to: serverId)
    }
}
