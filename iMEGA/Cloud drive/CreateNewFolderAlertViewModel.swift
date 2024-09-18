import MEGADesignToken
import MEGADomain
import MEGAL10n

@MainActor
final class CreateNewFolderAlertViewModel {
    struct AlertProperties: Equatable {
        let title: String
        let textFieldTextColor: UIColor
        let isActionEnabled: Bool
    }

    private let router: any CreateNewFolderAlertRouting
    private let nodeUseCase: any NodeUseCaseProtocol
    private let parentNode: NodeEntity
    private var continuation: CheckedContinuation<NodeEntity?, Never>?

    init(
        router: some CreateNewFolderAlertRouting,
        parentNode: NodeEntity,
        nodeUseCase: some NodeUseCaseProtocol
    ) {
        self.router = router
        self.parentNode = parentNode
        self.nodeUseCase = nodeUseCase
    }

    // MARK: - Interface methods.

    func waitUntilFinished() async -> NodeEntity? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func cancelAction() {
        continuation?.resume(with: .success(nil))
        continuation = nil
    }

    func createButtonTapped(withFolderName folderName: String) {
        Task { [weak self] in
            guard let self else {
                return
            }
            
            guard let name = folderName.trim else {
                cancelAction()
                return
            }

            await createFolder(withName: name)
        }
    }

    func shouldReturnCompletion(for text: String?) -> Bool {
        guard let text else { return true }
        return text.trim != nil && !text.containsInvalidFileFolderNameCharacters
    }

    func makeAlertProperties(with text: String) -> AlertProperties {
        let containsInvalidChars = text.containsInvalidFileFolderNameCharacters
        let title = newFolderNameAlertTitle(withInvalidChars: containsInvalidChars)
        let textColor = containsInvalidChars ? TokenColors.Text.error : TokenColors.Text.primary
        let isEnabled = (text.trim != nil && !containsInvalidChars)
        return .init(title: title, textFieldTextColor: textColor, isActionEnabled: isEnabled)
    }

    // MARK: - Private methods.

    private func newFolderNameAlertTitle(withInvalidChars containsInvalidChars: Bool) -> String {
        guard containsInvalidChars else { return Strings.Localizable.newFolder }
        return Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharactersToDisplay)
    }

    private func createFolder(withName name: String) async {
        let nodeEntity: NodeEntity?
        do {
            nodeEntity = try await nodeUseCase.createFolder(with: name, in: parentNode)
        } catch NodeCreationErrorEntity.nodeAlreadyExists {
            await showNodeAlreadyExistsError()
            nodeEntity = nil
        } catch {
            nodeEntity = nil
            MEGALogError("Unable to create node with name \(name): \(error)")
        }

        continuation?.resume(with: .success(nodeEntity))
        continuation = nil
    }

    private func showNodeAlreadyExistsError() async {
        await router.showNodeAlreadyExistsError()
    }
}
