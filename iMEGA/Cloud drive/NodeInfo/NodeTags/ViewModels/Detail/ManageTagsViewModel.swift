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

        $tagName
            .sink { [weak self] updatedTagName in
                guard let self else { return }
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
            .store(in: &subscriptions)
    }

    func addTag() {
        guard tagNameState == .valid else { return }
        existingTagsViewModel.addAndSelectNewTag(tagName)
        tagName = ""
        containsExistingTags = true
        hasTextFieldFocus = false
    }

    private func containsInvalidCharacters(in tagName: String) -> Bool {
        tagName.rangeOfCharacter(
            from: CharacterSet.alphanumerics.inverted.union(CharacterSet.uppercaseLetters)
        ) != nil
    }
}
