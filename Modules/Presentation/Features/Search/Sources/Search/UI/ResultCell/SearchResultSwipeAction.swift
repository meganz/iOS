import SwiftUI

public struct SearchResultSwipeAction: Identifiable, Hashable {
    public let id = UUID()
    public let image: Image
    public let backgroundColor: Color
    public let action: @MainActor () -> Void

    public init(image: Image, backgroundColor: Color, action: @MainActor @escaping () -> Void) {
        self.image = image
        self.backgroundColor = backgroundColor
        self.action = action
    }

    public static func == (lhs: SearchResultSwipeAction, rhs: SearchResultSwipeAction) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
