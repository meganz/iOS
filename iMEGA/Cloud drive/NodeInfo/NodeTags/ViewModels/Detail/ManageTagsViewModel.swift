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
    private var subscriptions: [AnyCancellable] = []

    init(navigationBarViewModel: ManageTagsViewNavigationBarViewModel, existingTagsViewModel: ExistingTagsViewModel) {
        self.navigationBarViewModel = navigationBarViewModel
        self.existingTagsViewModel = existingTagsViewModel
    }

    func addTag() {
        guard tagNameState == .valid else { return }
        existingTagsViewModel.addAndSelectNewTag(tagName)
        tagName = ""
        containsExistingTags = true
        hasTextFieldFocus = false
    }

    func validateAndUpdateTagNameStateIfRequired(with updatedTagName: String) {
        if updatedTagName.isEmpty {
            tagNameState = .empty
        } else if updatedTagName == "#" {
            tagName = ""
            tagNameState = .empty
        } else if containsInvalidCharacters(in: updatedTagName) {
            tagNameState = .invalid
        } else if updatedTagName.count > maxAllowedCharacterCount {
            tagNameState = .tooLong
        } else if containsUpperCaseCharacters(in: updatedTagName) {
            tagName = updatedTagName.lowercased()
            tagNameState = .valid
        } else {
            tagNameState = .valid
        }
    }

    func clearTextField() {
        tagName = ""
        tagNameState = .empty
    }

    private func containsInvalidCharacters(in tagName: String) -> Bool {
        tagName.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil
    }

    private func containsUpperCaseCharacters(in tagName: String) -> Bool {
        tagName.rangeOfCharacter(from: CharacterSet.uppercaseLetters) != nil
    }
}
