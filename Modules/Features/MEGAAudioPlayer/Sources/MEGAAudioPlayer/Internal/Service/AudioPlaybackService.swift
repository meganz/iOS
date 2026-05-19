import Combine
import Foundation
import MEGADomain
import SwiftUI

/// Single state projection the VM subscribes to. Bundling avoids declaring a
/// dozen separate publishers on the service protocol. 
struct AudioPlaybackState {
    var currentSource: PlaybackSource
    var currentNode: NodeEntity? { currentSource.primaryNode }
}

/// App-level audio service abstraction.
@MainActor
protocol AudioPlaybackServiceProtocol: AnyObject {
    var statePublisher: AnyPublisher<AudioPlaybackState?, Never> { get }

    func play(source: PlaybackSource)
}

/// Live implementation of `AudioPlaybackServiceProtocol`. Process-lifetime
/// singleton via `shared`. Currently a stub — engine, audio-session, remote
/// command, now-playing, and stats wiring land in the engine-migration
@MainActor
final class AudioPlaybackService: AudioPlaybackServiceProtocol {
    static let shared = AudioPlaybackService()

    private let stateSubject = CurrentValueSubject<AudioPlaybackState?, Never>(nil)

    var statePublisher: AnyPublisher<AudioPlaybackState?, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private init() {}

    func play(source: PlaybackSource) {
        // Engine not wired yet — to be implemented in the engine-migration sprint.
        // Until then, project the source into state so the VM (and three-dot
        // actions menu) has enough context to build the right action sheet.
        stateSubject.value = AudioPlaybackState(currentSource: source)
    }
}
