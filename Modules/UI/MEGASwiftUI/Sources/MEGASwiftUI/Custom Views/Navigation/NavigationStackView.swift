import SwiftUI

public struct NavigationStackView<Content: View>: View {
    private let content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        NavigationStack(root: content)
    }
}
