import Combine
import SwiftUI

final class NodeDescriptionFooterViewModel: ObservableObject {
    @Published var trailingText: String?
    let leadingText: String?

    var description: String?
    private let maxCharactersAllowed: Int

    init(leadingText: String?, description: String?, maxCharactersAllowed: Int) {
        self.leadingText = leadingText
        self.description = description
        self.maxCharactersAllowed = maxCharactersAllowed
    }

    func showTrailingText() {
        let numberOfCharacters = description?.unicodeScalars.count ?? 0
        trailingText = "\(numberOfCharacters)/\(maxCharactersAllowed)"
    }
}
