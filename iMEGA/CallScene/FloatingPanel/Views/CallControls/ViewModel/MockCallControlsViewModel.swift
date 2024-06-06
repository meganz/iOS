final class MockCallControlsViewModel: CallControlsViewModelProtocol {
    
    init(micEnabled: Bool, cameraEnabled: Bool, speakerEnabled: Bool, routeViewVisible: Bool) {
        self.micEnabled = micEnabled
        self.cameraEnabled = cameraEnabled
        self.speakerEnabled = speakerEnabled
        self.routeViewVisible = routeViewVisible
    }
    
    var micEnabled: Bool
    
    var cameraEnabled: Bool
    
    var speakerEnabled: Bool
    
    var routeViewVisible: Bool
    
    func endCallTapped() { }
    
    func toggleCameraTapped() async { }
    
    func toggleMicTapped() async { }
    
    func toggleSpeakerTapped() { }
    
    func switchCameraTapped() async { }
}
