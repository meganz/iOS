import SwiftUI

public struct OffsetPreferenceKey: PreferenceKey {
    public static let defaultValue = CGFloat.zero
    
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

public struct OffsetPreferenceView: ViewModifier {
    let space: CoordinateSpace
    
    public func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: OffsetPreferenceKey.self,
                                           value: -proxy.frame(in: space).origin.y)
                }
            )
    }
}

public extension View {
    func offset(in space: CoordinateSpace) -> some View {
        modifier(OffsetPreferenceView(space: space))
    }
}
