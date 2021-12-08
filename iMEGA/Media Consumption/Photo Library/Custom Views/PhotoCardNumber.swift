import SwiftUI

struct PhotoCardNumber: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .bottomTrailing)
    }
}

extension View {
    func photoCardNumber() -> some View {
        modifier(PhotoCardNumber())
    }
}
