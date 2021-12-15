import Foundation
import SwiftUI

struct FramePreferenceKey: PreferenceKey {
    static var defaultValue = CGRect.zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { }
}

struct FramePreferenceView: ViewModifier {
    let space: CoordinateSpace
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: FramePreferenceKey.self,
                                           value: proxy.frame(in: space))
                }
            )
    }
}

extension View {
    func frame(in space: CoordinateSpace) -> some View {
        modifier(FramePreferenceView(space: space))
    }
}
