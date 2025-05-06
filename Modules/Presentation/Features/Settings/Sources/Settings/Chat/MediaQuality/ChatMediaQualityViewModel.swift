import Foundation
import MEGADomain
import MEGAPreference

@MainActor
public final class ChatMediaQualityViewModel: ObservableObject {
    @PreferenceWrapper(key: PreferenceKeyEntity.chatImageQuality, defaultValue: 0)
    private var chatImageQuality: Int
    @PreferenceWrapper(key: PreferenceKeyEntity.chatVideoQuality, defaultValue: 2)
    private var chatVideoQuality: Int
    
    @Published var isImageQualityBottomSheetPresented = false
    @Published var imageMediaQuality: ChatMediaQuality = .auto
    var imageQualityOptions: [ChatMediaQuality] = ChatMediaQuality.imageQualityOptions()
    
    @Published var videoMediaQuality: ChatMediaQuality = .original
    @Published var isVideoQualityBottomSheetPresented = false
    var videoQualityOptions: [ChatMediaQuality] = ChatMediaQuality.videoQualityOptions()
    
    init(
        defaultPreferenceUseCase: some PreferenceUseCaseProtocol,
        groupPreferenceUseCase: some PreferenceUseCaseProtocol
    ) {
        $chatImageQuality.useCase = defaultPreferenceUseCase
        $chatVideoQuality.useCase = groupPreferenceUseCase
        imageMediaQuality = imageMediaQuality(from: chatImageQuality)
        videoMediaQuality = videoMediaQuality(from: chatVideoQuality)
    }
    
    func imageQualityViewTapped() {
        isImageQualityBottomSheetPresented.toggle()
    }
    
    func videoQualityViewTapped() {
        isVideoQualityBottomSheetPresented.toggle()
    }
    
    func imageQualityOptionTapped(_ option: ChatMediaQuality) {
        chatImageQuality = chatImageQuality(from: option)
        imageMediaQuality = option
        isImageQualityBottomSheetPresented.toggle()
    }
    
    func videoQualityOptionTapped(_ option: ChatMediaQuality) {
        chatVideoQuality = chatVideoQuality(from: option)
        videoMediaQuality = option
        isVideoQualityBottomSheetPresented.toggle()
    }
}

// MARK: - Mappers from legacy entity to presentation model and vice-versa
/// `ChatImageUploadQuality` and `ChatVideoUploadQuality` are defined in the app and used in Obj-C code,
/// not being able to use in the Settings module so using directly raw values.
extension ChatMediaQualityViewModel {
    func imageMediaQuality(from chatImageQuality: Int) -> ChatMediaQuality {
        if chatImageQuality == 1 {
            .original
        } else if chatImageQuality == 2 {
            .optimised
        } else {
            .auto
        }
    }
    
    func videoMediaQuality(from chatVideoQuality: Int) -> ChatMediaQuality {
        if chatVideoQuality == 1 {
            .low
        } else if chatVideoQuality == 3 {
            .high
        } else if chatVideoQuality == 5 {
            .original
        } else {
            . medium
        }
    }
    
    func chatImageQuality(from chatMediaQuality: ChatMediaQuality) -> Int {
        switch chatMediaQuality {
        case .original: 1
        case .optimised: 2
        default: 0
        }
    }
    
    func chatVideoQuality(from chatMediaQuality: ChatMediaQuality) -> Int {
        switch chatMediaQuality {
        case .original: 5
        case .low: 1
        case .high: 3
        default: 2
        }
    }
}
