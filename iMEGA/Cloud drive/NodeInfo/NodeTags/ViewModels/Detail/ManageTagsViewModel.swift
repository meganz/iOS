import Combine
import SwiftUI

@MainActor
final class ManageTagsViewModel: ObservableObject {
    enum TagNameState {
        case empty
        case invalid
        case tooLong
        case valid
    }

    // `doneButtonDisabled` will be handled in [SAO-1819]
    let navigationBarViewModel: ManageTagsViewNavigationBarViewModel
    let existingTagsViewModel: ExistingTagsViewModel

    @Published var tagName: String = ""
    @Published var tagNameState: TagNameState = .empty
    @Published var containsExistingTags = false
    @Published var hasTextFieldFocus: Bool = false
    private var maxAllowedCharacterCount = 32
    private var subscriptions: Set<AnyCancellable> = []

    init(navigationBarViewModel: ManageTagsViewNavigationBarViewModel, existingTagsViewModel: ExistingTagsViewModel) {
        self.navigationBarViewModel = navigationBarViewModel
        self.existingTagsViewModel = existingTagsViewModel
        monitorTagsLoadingStatus()
    }

    // MARK: - Interface methods.

    func addTag() {
        guard tagNameState == .valid else { return }
        existingTagsViewModel.addAndSelectNewTag(tagName)
        tagName = ""
        containsExistingTags = true
        hasTextFieldFocus = false
    }

    func validateAndUpdateTagNameStateIfRequired(with updatedTagName: String) {
        let formattedTagName = formatTagName(updatedTagName)
        updateTagNameState(for: formattedTagName)

        guard updatedTagName != formattedTagName else { return }
        tagName = formattedTagName
    }

    func clearTextField() {
        tagName = ""
        tagNameState = .empty
    }

    func loadAllTags() async {
        await existingTagsViewModel.searchTags(for: nil)
    }

    // MARK: - Private methods

    private func formatTagName(_ tagName: String) -> String {
        if tagName.hasPrefix("#") {
            return String(tagName.drop(while: { $0 == "#" }))
        } else if containsUpperCaseCharacters(in: tagName) {
            return tagName.lowercased()
        } else {
            return tagName
        }
    }

    private func updateTagNameState(for updatedTagName: String) {
        if updatedTagName.isEmpty {
            tagNameState = .empty
        } else if containsInvalidCharacters(in: updatedTagName) {
            tagNameState = .invalid
        } else if updatedTagName.count > maxAllowedCharacterCount {
            tagNameState = .tooLong
        } else {
            tagNameState = .valid
        }
    }

    private func containsInvalidCharacters(in tagName: String) -> Bool {
        tagName.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil
    }

    private func containsUpperCaseCharacters(in tagName: String) -> Bool {
        tagName.rangeOfCharacter(from: CharacterSet.uppercaseLetters) != nil
    }

    private func monitorTagsLoadingStatus() {
        existingTagsViewModel
            .$isLoading
            .sink { [weak self] isLoading in
                guard let self, !isLoading, existingTagsViewModel.isLoading else { return }
                containsExistingTags = existingTagsViewModel.containsTags
            }
            .store(in: &subscriptions)
    }
}
