import Combine
@testable import MEGA
import MEGADomain
import Testing

struct AudioPlayerUseCaseTests {
    private let shortWait: UInt64 = 100_000_000
    
    private func makeSUT(
        reloadPublisherFactory: () -> PassthroughSubject<[NodeEntity], Never> = { PassthroughSubject<[NodeEntity], Never>() }
    ) -> (sut: AudioPlayerUseCase, repo: MockAudioPlayerRepository) {
        let repo = MockAudioPlayerRepository(reloadItemPublisher: reloadPublisherFactory())
        let sut = AudioPlayerUseCase(repository: repo)
        return (sut, repo)
    }
    
    @Test("init does not register")
    func initDoesNotRegister() {
        let (_, repo) = makeSUT()
        #expect(repo.messages.isEmpty)
    }
    
    @Test("register MEGA delegate")
    func registerDelegates() async {
        let (sut, repo) = makeSUT()
        await sut.registerMEGADelegate()
        #expect(repo.messages == [.registerMEGADelegate])
    }
    
    @Test("unregister MEGA Delegate")
    func unregisterDelegates() async {
        let (sut, repo) = makeSUT()
        await sut.unregisterMEGADelegate()
        #expect(repo.messages == [.unregisterMEGADelegate])
    }
    
    @Test("reloadItemPublisher emits nothing without updates")
    func reloadPublisherNoUpdatesEmitsNothing() async throws {
        let (sut, _) = makeSUT()
        var received: [NodeEntity]?
        var cancellables = Set<AnyCancellable>()
        
        sut.reloadItemPublisher()
            .sink { value in received = value }
            .store(in: &cancellables)
        
        try await Task.sleep(nanoseconds: shortWait)
        #expect(received == nil)
    }
    
    @Test("reloadItemPublisher emits nodes on update")
    func reloadPublisherEmitsOnUpdate() async throws {
        let node = NodeEntity(handle: 1)
        let (sut, repo) = makeSUT()
        var received: [NodeEntity]?
        var cancellables = Set<AnyCancellable>()
        
        sut.reloadItemPublisher()
            .sink { value in received = value }
            .store(in: &cancellables)
        
        repo.simulateOnNodesUpdate(with: [node])
        try await Task.sleep(nanoseconds: shortWait)
        
        #expect(received != nil)
        #expect(received == [node])
    }
}
