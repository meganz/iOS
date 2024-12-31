import Combine
import MEGASwift
import SwiftUI

@MainActor
final class NodeTagViewModel {
    let tag: String
    let isSelected: Bool
    private let toggleSubject = PassthroughSubject<String, Never>()

    var formattedTag: String {
        ("#" + tag).forceLeftToRight()
    }

    init(tag: String, isSelected: Bool) {
        self.tag = tag
        self.isSelected = isSelected
    }

    func toggle() {
        toggleSubject.send(tag)
    }

    func observeToggles() -> AnyPublisher<String, Never> {
        toggleSubject.eraseToAnyPublisher()
    }
}
