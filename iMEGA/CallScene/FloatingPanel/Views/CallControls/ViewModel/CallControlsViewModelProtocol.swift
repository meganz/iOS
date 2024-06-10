protocol CallControlsViewModelProtocol: ObservableObject {
    var micEnabled: Bool { get }
    var cameraEnabled: Bool { get }
    var speakerEnabled: Bool { get }
    var routeViewVisible: Bool { get }
    func endCallTapped() async
    func toggleCameraTapped() async
    func toggleMicTapped() async
    func toggleSpeakerTapped()
    func switchCameraTapped() async
}
