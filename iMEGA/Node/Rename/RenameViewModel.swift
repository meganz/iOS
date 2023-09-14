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
    private let nodeActionUseCase: any NodeActionUseCaseProtocol
    
    init(
        router: any RenameViewRouting,
        type: RenameType,
        nodeActionUseCase: any NodeActionUseCaseProtocol
    ) {
        self.router = router
        self.type = type
        self.nodeActionUseCase = nodeActionUseCase
    }
    
    func rename(_ newName: String) async {
        // Depending on the RenameType, one or the other function of the NodeActionUseCase must be executed.
    }
    
    func isDuplicated(_ text: String) -> Bool {
        // Will check if the name entered by the user is duplicated, we take into account the RenameType to set the duplicity criterion
        return false
    }
    
    func containsInvalidChars(_ text: String) -> Bool {
        let invalidCharacterSet = CharacterSet(charactersIn: "|*/:<>?\"\\")
        return text.rangeOfCharacter(from: invalidCharacterSet) != nil
    }
    
    func textfieldText() -> String {
        // Initial text to be displayed in the alert's textfield
        return ""
    }
    
    func textfieldPlaceHolder() -> String {
        // Text to be displayed as placeholder of the alert's textfield
        return ""
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
        if containsInvalidChars(text) || isDuplicated(text) {
            return Colors.General.Red.ff3B30.color
        }
        return UIColor.label
    }
    
    func isActionButtonEnabled(text: String) -> Bool {
        !(
            text.isEmpty ||
            containsInvalidChars(text) ||
            isDuplicated(text)
        )
    }
}
