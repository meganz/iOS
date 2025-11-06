import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGAPermissions

public protocol CameraSwitching: Sendable {
    func switchCamera() async
}

/// Code extracted to have a shared implementation of camera front/back switching
/// used in
///   * CallControlsViewModel - when more button is not shown (switching is possible in the call UI)
///   * NavBar in MeetingParticipantsLayoutViewModel - when more button is show
public struct CameraSwitcher: CameraSwitching {
    var captureDeviceUseCase: any CaptureDeviceUseCaseProtocol
    var localVideoUseCase: any CallLocalVideoUseCaseProtocol
    
    public init(
        captureDeviceUseCase: any CaptureDeviceUseCaseProtocol,
        localVideoUseCase: any CallLocalVideoUseCaseProtocol
    ) {
        self.captureDeviceUseCase = captureDeviceUseCase
        self.localVideoUseCase = localVideoUseCase
    }
    
    public func switchCamera() async {
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(position: isBackCameraSelected() ? .front : .back) else {
            logError("Error getting camera localised name")
            return
        }
        do {
            try await localVideoUseCase.selectCamera(withLocalizedName: selectCameraLocalizedString)
        } catch {
            logError("Error selecting camera: \(error.localizedDescription)")
        }
    }
    
    private func isBackCameraSelected() -> Bool {
        captureDeviceUseCase.wideAngleCameraLocalizedName(position: .back) == localVideoUseCase.videoDeviceSelected()
    }
}
