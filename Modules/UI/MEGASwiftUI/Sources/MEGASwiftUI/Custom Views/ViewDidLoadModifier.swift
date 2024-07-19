import SwiftUI

struct ViewDidLoadModifier: ViewModifier {
    @State private var didLoad = false
    private let action: (() async -> Void)
    
    init(perform action: @escaping (() async -> Void)) {
        self.action = action
    }
    
    func body(content: Content) -> some View {
        content
            .task {
                if !didLoad {
                    didLoad.toggle()
                    await action()
                }
            }
    }
}

public extension View {
    func onLoad(perform action: @escaping (() async -> Void)) -> some View {
        modifier(ViewDidLoadModifier(perform: action))
    }
}
