import MEGAAppPresentation
import MEGADomain

enum QRSettingsKeyAction: ActionType {
    case onViewDidLoad
    case autoAcceptDidChange(Bool)
    case resetContactLink
}

final class QRSettingsViewModel: NSObject, ViewModelType {
    var invokeCommand: ((Command) -> Void)?
    
    enum Command: CommandType {
        case refreshAutoAccept(Bool)
        case contactLinkReset
    }
    
    private let contactLinkVerificationUseCase: any ContactLinkVerificationUseCaseProtocol
    
    private var autoAdditionTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    init(contactLinkVerificationUseCase: some ContactLinkVerificationUseCaseProtocol) {
        self.contactLinkVerificationUseCase = contactLinkVerificationUseCase
    }
    
    deinit {
        autoAdditionTask?.cancel()
    }
    
    func dispatch(_ action: QRSettingsKeyAction) {
        switch action {
        case .onViewDidLoad:
            Task {
                await updateAutoAcceptCurrentValue()
                observeQRCodeContactAutoAdditionEvents()
            }
            
        case .autoAcceptDidChange(let bool):
            Task {
                await updateContactLinksOption(enabled: bool)
            }
        case .resetContactLink:
            Task {
                await resetContactLink()
            }
        }
    }
    
    func resetContactLink() async {
        do {
            try await contactLinkVerificationUseCase.resetContactLink()
            invokeCommand?(.contactLinkReset)
        } catch {
            MEGALogError("[Contact Links Option] Error resetting the current contact link: \(error)")
        }
    }
    
    func updateContactLinksOption(enabled: Bool) async {
        do {
            try await contactLinkVerificationUseCase.updateContactLinksOption(enabled: enabled)
        } catch {
            MEGALogError("[Contact Links Option] Error updating the auto accept value: \(error)")
        }
    }
    
    func observeQRCodeContactAutoAdditionEvents() {
        autoAdditionTask = Task { [weak self, contactLinkVerificationUseCase] in
            for await _ in contactLinkVerificationUseCase.qrCodeContactAutoAdditionEvents {
                await self?.updateAutoAcceptCurrentValue()
            }
        }
    }
    
    func updateAutoAcceptCurrentValue() async {
        do {
            let isEnabled = try await contactLinkVerificationUseCase.contactLinksOption()
            invokeCommand?(.refreshAutoAccept(isEnabled))
        } catch {
            MEGALogError("[Contact Links Option] Error getting the auto accept value: \(error)")
        }
    }
}
