@preconcurrency import Combine
@testable import MEGA
import MEGADomain

final class MockAudioPlayerRepository: AudioPlayerRepositoryProtocol, @unchecked Sendable {
    var reloadItemPublisher: AnyPublisher<[NodeEntity], Never> { _reloadItemPublisher.eraseToAnyPublisher() }
    
    private let _reloadItemPublisher: PassthroughSubject<[NodeEntity], Never>
    
    init(reloadItemPublisher: PassthroughSubject<[NodeEntity], Never>) {
        self._reloadItemPublisher = reloadItemPublisher
    }
    
    enum Message {
        case registerMEGADelegate
        case unregisterMEGADelegate
    }
    
    static var newRepo: MockAudioPlayerRepository {
        let reloadItemPublisher = PassthroughSubject<[NodeEntity], Never>()
        let repo = MockAudioPlayerRepository(reloadItemPublisher: reloadItemPublisher)
        return repo
    }
    
    private(set) var messages = [Message]()
    
    func registerMEGADelegate() {
        messages.append(.registerMEGADelegate)
    }
    
    func unregisterMEGADelegate() {
        messages.append(.unregisterMEGADelegate)
    }
    
    func simulateOnNodesUpdate(with nodes: [NodeEntity]) {
        _reloadItemPublisher.send(nodes)
    }
}
