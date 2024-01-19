extension PasswordReminderViewController {
    
    @objc func requestStopAudioPlayerSession() {
        let streamingInfoUseCase = StreamingInfoUseCase()
        if AudioPlayerManager.shared.isPlayerAlive() {
            streamingInfoUseCase.stopServer()
        }
    }
}
