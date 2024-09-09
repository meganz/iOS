import Combine
import SwiftUI

final class NodeDescriptionFooterViewModel: ObservableObject {
    @Published var trailingText: String?
    var leadingText: String?

    var description: String
    private let maxCharactersAllowed: Int

    init(leadingText: String?, description: String, maxCharactersAllowed: Int) {
        self.leadingText = leadingText
        self.description = description
        self.maxCharactersAllowed = maxCharactersAllowed
    }

    func showTrailingText() {
        let numberOfCharacters = description.utf16.count
        trailingText = "\(numberOfCharacters)/\(maxCharactersAllowed)"
    }
}
