import Foundation

enum MeetingCreatingViewAction: ActionType {
    case onViewReady

    case addChatLocalVideo(delegate: MEGAChatVideoDelegate)
    case didTapMicroPhoneButton
    case didTapVideoButton
    case didTapSpeakerButton
    case didTapSwitchCameraButton
    case didTapCloseButton
    case didTapStartMeetingButton
    case updateMeetingName(String)
}

enum MeetingCameraType: Int {
    case back
    case front
}

protocol MeetingCreatingViewRouting: Routing {
    func dismiss()
    func goToMeetingRoom(chatRoom: MEGAChatRoom)
}

final class MeetingCreatingViewModel: ViewModelType {
    enum Command: CommandType {
        case configView(title: String, subtitle: String)
        case updateMeetingName(String)
        
        case updateVideoButton(enabled: Bool)
        case updateSpeakerButton(enabled: Bool)
        case updateMicroPhoneButton(enabled: Bool)

        case updateCameraSwitchType(type: MeetingCameraType)
        case loadingMeeting
    }
    
    // MARK: - Private properties
    private let router: MeetingCreatingViewRouting
    private var meetingName = ""
    private let videoDevices: [String]
    
    private let meetingUseCase: MeetingCreatingUseCaseProtocol
    private let callManagerUseCase: CallManagerUseCaseProtocol
    private let callsUseCase: CallsUseCaseProtocol

    private var isVideoEnabled = false
    private var isSpeakerEnabled = false
    private var isMicroPhoneEnabled = false
    private var cameraType = MeetingCameraType.back
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: MeetingCreatingViewRouting, meetingUseCase: MeetingCreatingUseCaseProtocol) {
        self.router = router
        self.meetingUseCase = meetingUseCase
        callManagerUseCase = CallManagerUseCase()
        callsUseCase = CallsUseCase(repository: CallsRepository())
        videoDevices = meetingUseCase.videoDevices()
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: MeetingCreatingViewAction) {
        switch action {
        case .onViewReady:
            meetingName = String(format: NSLocalizedString("%@ Meeting", comment: "Meeting Title"), meetingUseCase.getUsername())
            invokeCommand?(.configView(title: meetingName, subtitle: ""))
        case .didTapMicroPhoneButton:
            isMicroPhoneEnabled = !isMicroPhoneEnabled
            invokeCommand?(.updateMicroPhoneButton(enabled: isMicroPhoneEnabled))
        case .didTapVideoButton:
            didTapVideoButton()
        case .didTapSpeakerButton:
            isSpeakerEnabled = !isSpeakerEnabled
            invokeCommand?(.updateSpeakerButton(enabled: isSpeakerEnabled))

        case .didTapStartMeetingButton:
            invokeCommand?(.loadingMeeting)
            startChatCall()
            
        case .didTapCloseButton:
            meetingUseCase.releaseDevice()
            router.dismiss()
        case .updateMeetingName(let name):
            meetingName = name
            invokeCommand?(.updateMeetingName(meetingName))    
        case .didTapSwitchCameraButton:
            cameraType = (cameraType == .back) ? .front : .back
            meetingUseCase.setChatVideoInDevices(type: cameraType)
            invokeCommand?(.updateCameraSwitchType(type: cameraType))
        case .addChatLocalVideo(let delegate):
            meetingUseCase.addChatLocalVideo(delegate: delegate)
        }
    }
    
    private func startChatCall() {
        meetingUseCase.startChatCall(meetingName: meetingName, enableVideo: isVideoEnabled, enableAudio: isMicroPhoneEnabled) { [weak self] in
            switch $0 {
            case .success(let chatroom):
                self?.router.goToMeetingRoom(chatRoom: chatroom)
            case .failure(_):
                self?.router.dismiss()
            }
        }
    }
    
    private func didTapVideoButton() {
        DevicePermissionsHelper.audioPermissionModal(true, forIncomingCall: false) { (granted) in
            if granted {
                DevicePermissionsHelper.videoPermission { (videoPermission) in
                    if videoPermission {
                        self.isVideoEnabled = !self.isVideoEnabled
                        if self.isVideoEnabled {
                            self.meetingUseCase.openVideoDevice()
                        } else {
                            self.meetingUseCase.releaseDevice()
                        }
                        self.invokeCommand?(.updateVideoButton(enabled: self.isVideoEnabled))

                    } else {
                        DevicePermissionsHelper.alertVideoPermission(completionHandler: nil)
                    }
                }
                
            } else {
                DevicePermissionsHelper.alertAudioPermission(forIncomingCall: false)
            }
        }
    }
}
