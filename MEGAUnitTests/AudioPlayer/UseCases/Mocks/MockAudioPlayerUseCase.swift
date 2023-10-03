import Combine
@testable import MEGA
import MEGADomain

final class MockAudioPlayerUseCase: AudioPlayerUseCaseProtocol {
    
    func registerMEGADelegate() async {
        
    }
    
    func unregisterMEGADelegate() async {
        
    }
    
    func reloadItemPublisher() -> AnyPublisher<[NodeEntity], Never> {
        Just([]).eraseToAnyPublisher()
    }
}
