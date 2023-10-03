import Combine
@testable import MEGA
import MEGADomain
import XCTest

final class AudioPlayerUseCaseTests: XCTestCase {
    
    private var subscriptions = [AnyCancellable]()
    
    func testInit_doesNotRegister() {
        let (_, repository) = makeSUT()
        
        XCTAssertTrue(repository.messages.isEmpty, "Expect to not triggering sdk")
    }
    
    func testRegisterMEGADelegate_registerDelegate() async {
        let (sut, repository) = makeSUT()
        
        await sut.registerMEGADelegate()
        
        XCTAssertEqual(repository.messages, [ .registerMEGADelegate ])
    }
    
    func testUnregisterMEGADelegate_unregisterDelegate() async {
        let (sut, repository) = makeSUT()
        
        await sut.unregisterMEGADelegate()
        
        XCTAssertEqual(repository.messages, [ .unregisterMEGADelegate ])
    }
    
    func testReloadItemPublisher_whenNoNodesUpdate_DoesNotReloadsItem() {
        let (sut, _) = makeSUT()
        var receivedEntities: [NodeEntity]?
        let exp = expectation(description: "Wait for subscription")
        exp.isInverted = true
        sut.reloadItemPublisher()
            .sink(receiveValue: { nodeEntities in
                receivedEntities = nodeEntities
                exp.fulfill()
            })
            .store(in: &subscriptions)
        wait(for: [exp], timeout: 0.1)
        
        XCTAssertNil(receivedEntities)
    }
    
    func testReloadItemPublisher_whenHasNodesUpdate_DoesNotReloadsItem() {
        let node = NodeEntity(handle: 1)
        let (sut, repository) = makeSUT()
        var receivedEntities: [NodeEntity]?
        let exp = expectation(description: "Wait for subscription")
        sut.reloadItemPublisher()
            .sink(receiveValue: { nodeEntities in
                receivedEntities = nodeEntities
                exp.fulfill()
            })
            .store(in: &subscriptions)
        
        repository.simulateOnNodesUpdate(with: [node])
        wait(for: [exp], timeout: 0.1)
        
        XCTAssertNotNil(receivedEntities)
        XCTAssertEqual(receivedEntities, [node])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        reloadItemPublisher: () -> PassthroughSubject<[NodeEntity], Never> = {
            let subject = PassthroughSubject<[NodeEntity], Never>()
            return subject
        },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: AudioPlayerUseCase, repository: MockAudioPlayerRepository) {
        let repository = MockAudioPlayerRepository(reloadItemPublisher: reloadItemPublisher())
        let sut = AudioPlayerUseCase(repository: repository)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        trackForMemoryLeaks(on: repository, file: file, line: line)
        return (sut, repository)
    }
    
}
