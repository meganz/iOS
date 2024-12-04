import SwiftUI

public struct FramePreferenceKey: PreferenceKey {
    public static let defaultValue = CGRect.zero
    
    public static func reduce(value: inout CGRect, nextValue: () -> CGRect) { }
}

public struct FramePreferenceView: ViewModifier {
    let space: CoordinateSpace
    
    public func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: FramePreferenceKey.self,
                                           value: proxy.frame(in: space))
                }
            )
    }
}

public extension View {
    func frame(in space: CoordinateSpace) -> some View {
        modifier(FramePreferenceView(space: space))
    }
}
