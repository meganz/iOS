import MEGADomain
import MEGAL10n
import MEGAPresentation

protocol RenameViewRouting: Routing {
    func renamingFinishedSuccessfully()
    func renamingFinishedWithError()
}

struct RenameViewModel {
    private let router: any RenameViewRouting
    private let type: RenameType
    private let renameUseCase: any RenameUseCaseProtocol
    
    init(
        router: any RenameViewRouting,
        type: RenameType,
        renameUseCase: any RenameUseCaseProtocol
    ) {
        self.router = router
        self.type = type
        self.renameUseCase = renameUseCase
    }
    
    func rename(_ newName: String) async {
        switch type {
        case .device(let renameEntity):
            do {
                try await renameUseCase.renameDevice(renameEntity.deviceId, newName: newName)
                router.renamingFinishedSuccessfully()
            } catch {
                router.renamingFinishedWithError()
            }
        }
    }
    
    func isDuplicated(_ text: String) -> Bool {
        switch type {
        case .device(let renameEntity):
            return renameEntity.otherDeviceNames.contains(text)
        }
    }
    
    func containsInvalidChars(_ text: String) -> Bool {
        let invalidCharacterSet = CharacterSet(charactersIn: "|*/:<>?\"\\")
        return text.rangeOfCharacter(from: invalidCharacterSet) != nil
    }
    
    func textfieldText() -> String {
        switch type {
        case .device(let renameEntity):
            return renameEntity.deviceOldName
        }
    }
    
    func textfieldPlaceHolder() -> String {
        switch type {
        case .device:
            return Strings.Localizable.Device.Center.Rename.Device.title
        }
    }
    
    func alertTitle(text: String) -> String {
        if containsInvalidChars(text) {
            return Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharacters)
        } else if isDuplicated(text) {
            return Strings.Localizable.Device.Center.Rename.Device.Duplicated.name
        }
        
        return Strings.Localizable.rename
    }
    
    func alertMessage(text: String) -> String {
        isDuplicated(text) ?
            Strings.Localizable.Device.Center.Rename.Device.Different.name :
            Strings.Localizable.renameNodeMessage
    }
    
    func alertTextsColor(text: String) -> UIColor {
        containsInvalidChars(text) || isDuplicated(text) ? Colors.General.Red.ff3B30.color : UIColor.label
    }
    
    func isActionButtonEnabled(text: String) -> Bool {
        !(
            text.isEmpty ||
            containsInvalidChars(text) ||
            isDuplicated(text)
        )
    }
}
