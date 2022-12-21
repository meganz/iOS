import MEGADomain

@objc final class AudioSessionUseCaseOCWrapper: NSObject {
    let audioSessionUseCase = AudioSessionUseCase(audioSessionRepository: AudioSessionRepository(audioSession: AVAudioSession.sharedInstance(), callActionManager: CallActionManager.shared))
    
    @objc func configureCallAudioSession() {
        audioSessionUseCase.configureCallAudioSession()
    }
    
    @objc func configureDefaultAudioSession() {
        audioSessionUseCase.configureDefaultAudioSession()
    }
    
    @objc func configureVideoAudioSession() {
        audioSessionUseCase.configureVideoAudioSession()
    }
    
    @objc func setSpeakerEnabled(_ enabled: Bool) {
        enabled ? enableLoudSpeaker() : disableLoudSpeaker()
    }
    
    private func enableLoudSpeaker() {
        audioSessionUseCase.enableLoudSpeaker()
    }
    
    private func disableLoudSpeaker() {
        audioSessionUseCase.disableLoudSpeaker()
    }
}
