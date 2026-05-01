import MEGADomain
import SwiftUI

public struct FloatingAddAction: Sendable, Identifiable {
    public var id: String { title }
    let image: Image
    let title: String
    let action: @MainActor () -> Void

    public init(
        image: Image,
        title: String,
        action: @escaping @MainActor () -> Void
    ) {
        self.image = image
        self.title = title
        self.action = action
    }
}
