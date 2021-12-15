import Foundation
import SwiftUI

struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue = CGFloat.zero
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

struct OffsetPreferenceView: ViewModifier {
    let space: CoordinateSpace
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: OffsetPreferenceKey.self,
                                           value: -proxy.frame(in: space).origin.y)
                }
            )
    }
}

extension View {
    func offset(in space: CoordinateSpace) -> some View {
        modifier(OffsetPreferenceView(space: space))
    }
}
