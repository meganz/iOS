import MEGADomain

extension AudioSessionUseCase where T == AudioSessionRepository {
    static var `default`: AudioSessionUseCase {
        AudioSessionUseCase(audioSessionRepository: AudioSessionRepository(audioSession: AVAudioSession.sharedInstance()))
    }
}
