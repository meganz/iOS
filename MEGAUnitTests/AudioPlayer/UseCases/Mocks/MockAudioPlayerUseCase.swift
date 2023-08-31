import Combine
@testable import MEGA
import MEGADomain
import MEGASDKRepoMock

final class MockAudioPlayerUseCase: AudioPlayerUseCaseProtocol {
    private(set) var registerMEGADelegateCallCount = 0
    private(set) var unregisterMEGADelegateCallCount = 0
    
    private let subject = PassthroughSubject<[NodeEntity], Never>()
    
    func registerMEGADelegate() {
        registerMEGADelegateCallCount += 1
    }
    
    func unregisterMEGADelegate() {
        unregisterMEGADelegateCallCount += 1
    }
    
    func reloadItemPublisher() -> AnyPublisher<[NodeEntity], Never> {
        subject
            .eraseToAnyPublisher()
    }
    
    func simulateOnNodesUpdate(_ nodeList: MockNodeList, sdk: MockSdk) {
        sdk.setNodes(nodeList.toNodeArray())
        subject.send(nodeList.toNodeArray().toNodeEntities())
    }
}
