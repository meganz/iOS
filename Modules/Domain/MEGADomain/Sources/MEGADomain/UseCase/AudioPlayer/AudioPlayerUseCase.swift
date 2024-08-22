import Combine

public protocol AudioPlayerUseCaseProtocol: AnyObject, Sendable {
    func registerMEGADelegate() async
    func unregisterMEGADelegate() async
    func reloadItemPublisher() -> AnyPublisher<[NodeEntity], Never>
}

public final class AudioPlayerUseCase: AudioPlayerUseCaseProtocol {
    private let repository: any AudioPlayerRepositoryProtocol
    
    public init(repository: some AudioPlayerRepositoryProtocol) {
        self.repository = repository
    }
    
    public func registerMEGADelegate() async {
        await repository.registerMEGADelegate()
    }
    
    public func unregisterMEGADelegate() async {
        await repository.unregisterMEGADelegate()
    }
    
    public func reloadItemPublisher() -> AnyPublisher<[NodeEntity], Never> {
        repository.reloadItemPublisher
    }
}
