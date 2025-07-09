import Foundation
import Combine

@MainActor
class MEGABasePlayer: NSObject, PlaybackStateObservable {
    private let stateSubject: CurrentValueSubject<PlaybackState, Never> = .init(.stopped)
    private let currentTimeSubject: CurrentValueSubject<Duration, Never> = .init(.seconds(0))
    private let durationSubject: CurrentValueSubject<Duration, Never> = .init(.seconds(0))

    var state: PlaybackState {
        get { stateSubject.value }
        set { stateSubject.send(newValue) }
    }

    var currentTime: Duration {
        get { currentTimeSubject.value }
        set { currentTimeSubject.send(newValue) }
    }

    var duration: Duration {
        get { durationSubject.value }
        set { durationSubject.send(newValue) }
    }

    var statePublisher: AnyPublisher<PlaybackState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentTimePublisher: AnyPublisher<Duration, Never> {
        currentTimeSubject.eraseToAnyPublisher()
    }

    var durationPublisher: AnyPublisher<Duration, Never> {
        durationSubject.eraseToAnyPublisher()
    }

    let streamingUseCase: any StreamingUseCaseProtocol

    init(streamingUseCase: some StreamingUseCaseProtocol) {
        self.streamingUseCase = streamingUseCase
        super.init()
    }
}
