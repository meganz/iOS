import Combine
import SwiftUI

public protocol KeyboardHeightHandlingProtocol {
    var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> { get }
}

public struct KeyboardHeightHandling: KeyboardHeightHandlingProtocol {
    private let notificationCenter: NotificationCenter
    
    public init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }
    
    public var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> {
        let keyboardWillShowPublisher = notificationCenter
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .merge(with: notificationCenter.publisher(for: UIResponder.keyboardWillChangeFrameNotification))
            .map { notification in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return withAnimation(.easeInOut(duration: 0.16)) { CGFloat.zero }
                }
                return withAnimation(.easeInOut(duration: 0.16)) { frame.height }
            }
        
        let keyboardWillHideNotification = notificationCenter
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .compactMap { _ in CGFloat.zero }
        
        return Publishers.Merge(keyboardWillShowPublisher, keyboardWillHideNotification)
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

public final class KeyboardHeightStore: ObservableObject {
    @Published private(set) var newKeyboardHeight: CGFloat = 0
    @Published private(set) var bottomPadding: CGFloat = 0
    private let keyboardHandling: any KeyboardHeightHandlingProtocol
    private var subscriptions = Set<AnyCancellable>()
    
    init(keyboardHandling: some KeyboardHeightHandlingProtocol) {
        self.keyboardHandling = keyboardHandling
        subscribeToKeyboardHeightPublishers()
    }
    
    deinit {
        subscriptions.removeAll()
    }
    
    private func subscribeToKeyboardHeightPublishers() {
        keyboardHandling.keyboardHeightPublisher
            .sink { [weak self] newHeight in
                guard let self else { return }
                newKeyboardHeight = newHeight
            }
            .store(in: &subscriptions)
    }
    
    @MainActor
    func updateBottomPadding(bottomViewInset: CGFloat, newKeyboardHeight: CGFloat) {
        bottomPadding = newKeyboardHeight > 0 ? newKeyboardHeight - bottomViewInset : newKeyboardHeight
    }
}

struct AdaptsToKeyboardModifier: ViewModifier {
    @StateObject private var keyboardHandler = KeyboardHeightStore(
        keyboardHandling: KeyboardHeightHandling(notificationCenter: .default)
    )
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .padding(.bottom, self.keyboardHandler.bottomPadding)
                .onChange(of: self.keyboardHandler.newKeyboardHeight) { height in
                    self.keyboardHandler.updateBottomPadding(
                        bottomViewInset: geometry.safeAreaInsets.bottom,
                        newKeyboardHeight: height
                    )
                }
        }
    }
}

public extension View {
    /// Adds listener to the keyboard's visibility changes and adjust the content's bottom padding based on the keyboard's new frame
    func adaptsToKeyboard() -> some View {
        return modifier(AdaptsToKeyboardModifier())
    }
}
