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
    case updateFirstName(String)
    case updateLastName(String)

}

enum MeetingCameraType: Int {
    case back
    case front
}

@objc
enum MeetingConfigurationType: Int {
    case start
    case join
}

final class MeetingCreatingViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(title: String, subtitle: String, type: MeetingConfigurationType)
        case updateMeetingName(String)
        
        case updateVideoButton(enabled: Bool)
        case updateSpeakerButton(enabled: Bool)
        case updateMicroPhoneButton(enabled: Bool)

        case updateCameraSwitchType(type: MeetingCameraType)
        case loadingStartMeeting
        case loadingEndMeeting

    }
    
    // MARK: - Private properties
    private let router: MeetingCreatingViewRouting
    private var meetingName = ""
    private var firstName = ""
    private var lastName = ""

    private let videoDevices: [String]
    private let type: MeetingConfigurationType
    private let link: String?
    
    private let meetingUseCase: MeetingCreatingUseCaseProtocol
    private let callsUseCase: CallsUseCaseProtocol

    private var isVideoEnabled = false
    private var isSpeakerEnabled = false
    private var isMuteMicroPhoneEnabled = true
    private var cameraType = MeetingCameraType.back
    
    private var chatId: UInt64?
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: MeetingCreatingViewRouting, type: MeetingConfigurationType, meetingUseCase: MeetingCreatingUseCaseProtocol, link: String?) {
        self.router = router
        self.type = type
        self.meetingUseCase = meetingUseCase
        self.link = link
        callsUseCase = CallsUseCase(repository: CallsRepository())
        videoDevices = meetingUseCase.videoDevices()

    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: MeetingCreatingViewAction) {
        switch action {
        case .onViewReady:
            switch type {
            case .join:
                guard let link = link else {
                    return
                }
                checkChatLink(link: link)
            case .start:
                meetingName = String(format: NSLocalizedString("%@ Meeting", comment: "Meeting Title"), meetingUseCase.getUsername())
                invokeCommand?(.configView(title: meetingName, subtitle: "", type: type))
            }

        case .didTapMicroPhoneButton:
            didTapMicroPhoneButton()
        case .didTapVideoButton:
            didTapVideoButton()
        case .didTapSpeakerButton:
            isSpeakerEnabled = !isSpeakerEnabled
            invokeCommand?(.updateSpeakerButton(enabled: isSpeakerEnabled))
            
        case .didTapStartMeetingButton:
            switch type {
            case .join:
                guard let chatId = chatId else {
                    return
                }
                joinChatCall(chatId: chatId)
            case .start:
                startChatCall()
            }
            invokeCommand?(.loadingStartMeeting)
        case .didTapCloseButton:
            meetingUseCase.releaseDevice()
            router.dismiss(completion: {})
        case .updateMeetingName(let name):
            meetingName = name
            invokeCommand?(.updateMeetingName(meetingName))    
        case .didTapSwitchCameraButton:
            cameraType = (cameraType == .back) ? .front : .back
            meetingUseCase.setChatVideoInDevices(type: cameraType)
            invokeCommand?(.updateCameraSwitchType(type: cameraType))
        case .addChatLocalVideo(let delegate):
            meetingUseCase.addChatLocalVideo(delegate: delegate)
        case .updateFirstName(let name):
            firstName = name
        case .updateLastName(let name):
            lastName = name
        }
    }
    
    private func createEphemeralAccountAndJoinChat(chatId: UInt64) {
        meetingUseCase.createEphemeralAccountAndJoinChat(firstName: firstName, lastName: lastName) { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case .success(_):
                self.joinChatCall(chatId: chatId)
            case .failure(_):
                self.router.dismiss(completion: {})
            }
        }
    }
    
    private func joinChatCall(chatId: UInt64) {
        
        meetingUseCase.joinChatCall(forChatId: chatId, enableVideo: isVideoEnabled, enableAudio: !isMuteMicroPhoneEnabled) { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case .success(let chatRoom):
                guard let call = self.meetingUseCase.getCall(forChatId: chatRoom.chatId) else { return }
                self.router.dismiss(completion: {
                self.router.goToMeetingRoom(chatRoom: chatRoom, call: call, isVideoEnabled: self.isVideoEnabled)
                })
            case .failure(_):
                self.router.dismiss(completion: {})
            }
        }
    }
    
    private func startChatCall() {
        meetingUseCase.startChatCall(meetingName: meetingName, enableVideo: isVideoEnabled, enableAudio: !isMuteMicroPhoneEnabled) { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case .success(let chatRoom):
                guard let call = self.meetingUseCase.getCall(forChatId: chatRoom.chatId) else {
                    self.router.dismiss(completion: {})
                    return
                }
                self.router.dismiss(completion: {
                self.router.goToMeetingRoom(chatRoom: chatRoom, call: call, isVideoEnabled: self.isVideoEnabled)
                })
            case .failure(_):
                self.router.dismiss(completion: {})
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
                            self.meetingUseCase.setChatVideoInDevices(type: .front)
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
    
    private func didTapMicroPhoneButton() {
        DevicePermissionsHelper.audioPermissionModal(true, forIncomingCall: false) { (granted) in
            if granted {
                self.isMuteMicroPhoneEnabled = !self.isMuteMicroPhoneEnabled
                self.invokeCommand?(.updateMicroPhoneButton(enabled: self.isMuteMicroPhoneEnabled))
            } else {
                DevicePermissionsHelper.alertAudioPermission(forIncomingCall: false)
            }
        }
    }
    
    private func checkChatLink(link: String) {
        invokeCommand?(.loadingStartMeeting)
        
        meetingUseCase.checkChatLink(link: link) { [weak self] in
            guard let self = self else { return }
            self.invokeCommand?(.loadingEndMeeting)

            switch $0 {
            case .success(let chatRoom):
                self.invokeCommand?(.configView(title: chatRoom.title ?? "", subtitle: link, type: .join))
                self.chatId = chatRoom.chatId
            case .failure(_):
                self.router.dismiss(completion: {})
            }
        }
    }
}
