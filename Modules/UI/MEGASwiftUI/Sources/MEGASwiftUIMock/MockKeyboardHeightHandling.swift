import Combine
import Foundation
import MEGASwiftUI

public class MockKeyboardHeightHandling: KeyboardHeightHandlingProtocol {
    public let keyboardNotificationSubject = PassthroughSubject<CGFloat, Never>()
    
    public init() {}
    
    public var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> {
        keyboardNotificationSubject.eraseToAnyPublisher()
    }
}
