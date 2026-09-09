import Combine
@testable import MEGA
import MEGADomain
import MEGASwift

final class MockAudioPlayerUseCase: AudioPlayerUseCaseProtocol, @unchecked Sendable {
    @Atomic var registerMEGADelegate_callTimes = 0
    @Atomic var unregisterMEGADelegate_callTimes = 0
    
    func registerMEGADelegate() async {
        $registerMEGADelegate_callTimes.mutate { $0 += 1 }
    }
    
    func unregisterMEGADelegate() async {
        $unregisterMEGADelegate_callTimes.mutate { $0 += 1 }
    }
    
    func reloadItemPublisher() -> AnyPublisher<[NodeEntity], Never> {
        Just([]).eraseToAnyPublisher()
    }
}
