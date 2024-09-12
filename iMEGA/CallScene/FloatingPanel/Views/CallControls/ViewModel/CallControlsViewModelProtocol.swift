@MainActor
protocol CallControlsViewModelProtocol: ObservableObject {
    var micEnabled: Bool { get }
    var cameraEnabled: Bool { get }
    var speakerEnabled: Bool { get }
    var routeViewVisible: Bool { get }
    var showMoreButton: Bool { get }
    func endCallTapped() async
    func toggleCameraTapped() async
    func toggleMicTapped() async
    func toggleSpeakerTapped()
    func switchCameraTapped() async
    func moreButtonTapped() async
    func checkRaiseHandBadge() async
}
