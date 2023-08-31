import Combine
import MEGADomain
import MEGASdk

protocol AudioPlayerUseCaseProtocol {
    func registerMEGADelegate() async
    func unregisterMEGADelegate() async
    func reloadItemPublisher() -> AnyPublisher<[NodeEntity], Never>
}

final class AudioPlayerUseCase: AudioPlayerUseCaseProtocol {
    private let repository: any AudioPlayerRepositoryProtocol
    
    init(repository: some AudioPlayerRepositoryProtocol) {
        self.repository = repository
    }
    
    func registerMEGADelegate() async {
        await repository.registerMEGADelegate()
    }
    
    func unregisterMEGADelegate() async {
        await repository.unregisterMEGADelegate()
    }
    
    func reloadItemPublisher() -> AnyPublisher<[NodeEntity], Never> {
        repository.reloadItemPublisher
    }
}
