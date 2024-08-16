import Combine

final class NodeDescriptionKeyboardSubscriptions {
    enum KeyboardSubscription {
        case didShow
        case didHide
    }

    var publisher: AnyPublisher<KeyboardSubscription, Never> {
        passthroughSubject.eraseToAnyPublisher()
    }

    private var passthroughSubject = PassthroughSubject<KeyboardSubscription, Never>()
    private var subscriptions = Set<AnyCancellable>()

    init() {
        registerForKeyboardNotifications()
    }

    private func registerForKeyboardNotifications() {
        keyboardShownNotification()
        keyboardHiddenNotification()
    }

    private func keyboardShownNotification() {
        NotificationCenter
            .default
            .publisher(for: UIResponder.keyboardDidShowNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                passthroughSubject.send(.didShow)
            }
            .store(in: &subscriptions)
    }

    private func keyboardHiddenNotification() {
        NotificationCenter
            .default
            .publisher(for: UIResponder.keyboardDidHideNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                passthroughSubject.send(.didHide)
            }
            .store(in: &subscriptions)
    }
}
