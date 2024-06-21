final class MockCallControlsViewModel: CallControlsViewModelProtocol {
    
    init(
        micEnabled: Bool,
        cameraEnabled: Bool,
        speakerEnabled: Bool,
        routeViewVisible: Bool,
        showMoreButton: Bool = false
    ) {
        self.micEnabled = micEnabled
        self.cameraEnabled = cameraEnabled
        self.speakerEnabled = speakerEnabled
        self.routeViewVisible = routeViewVisible
        self.showMoreButton = showMoreButton
    }
    
    var micEnabled: Bool
    
    var cameraEnabled: Bool
    
    var speakerEnabled: Bool
    
    var routeViewVisible: Bool
    
    var showMoreButton: Bool
        
    func moreButtonTapped() async {}
    
    func endCallTapped() async { }
    
    func toggleCameraTapped() async { }
    
    func toggleMicTapped() async { }
    
    func toggleSpeakerTapped() { }
    
    func switchCameraTapped() async { }
    
    func checkRaiseHandBadge() async { }
}
