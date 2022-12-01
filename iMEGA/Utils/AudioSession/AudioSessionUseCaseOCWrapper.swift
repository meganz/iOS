import MEGADomain

@objc final class AudioSessionUseCaseOCWrapper: NSObject {
    let audioSessionUseCase = AudioSessionUseCase(audioSessionRepository: AudioSessionRepository(audioSession: AVAudioSession.sharedInstance(), callActionManager: CallActionManager.shared))
    
    @objc func configureMeetingAudioSession() {
        audioSessionUseCase.configureMeetingAudioSession()
    }
    
    @objc func configureDefaultAudioSession() {
        audioSessionUseCase.configureDefaultAudioSession()
    }
    
    @objc func configureVideoAudioSession() {
        audioSessionUseCase.configureVideoAudioSession()
    }
    
    @objc func setSpeakerEnabled(_ enabled: Bool) {
        audioSessionUseCase.setSpeaker(enabled: enabled, completion: nil)
    }
}
