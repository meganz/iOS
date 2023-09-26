import Combine
import Foundation
import UIKit

public protocol KeyboardVisibiltyHandling {
    var keyboardPublisher: AnyPublisher<Bool, Never> { get }
}

public class KeyboardVisibiltyHandler: KeyboardVisibiltyHandling {
    let notificationCenter: NotificationCenter

    public init(
        notificationCenter: NotificationCenter = .default
    ) {
        self.notificationCenter = notificationCenter
    }

    public var keyboardPublisher: AnyPublisher<Bool, Never> {
        let keyboardWillShowPublisher = notificationCenter
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .map { _ in true }
        let keyboardWillHidePublisher = notificationCenter
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in false }

        return Publishers.Merge(keyboardWillShowPublisher, keyboardWillHidePublisher)
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

public class MockKeyboardVisibilityHandler: KeyboardVisibiltyHandling {
    let isKeyboardVisible: Bool

    public init(
        isKeyboardVisible: Bool = false
    ) {
        self.isKeyboardVisible = isKeyboardVisible
    }

    public var keyboardPublisher: AnyPublisher<Bool, Never> {
        Just(isKeyboardVisible).eraseToAnyPublisher()
    }
}
