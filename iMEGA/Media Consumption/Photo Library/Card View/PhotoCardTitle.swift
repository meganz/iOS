import SwiftUI

struct PhotoCardTitle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(MEGAAppColor.White._FFFFFF.color)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [MEGAAppColor.Black._000000.color.opacity(0.3), MEGAAppColor.Black._000000.color.opacity(0)], startPoint: .top, endPoint: .bottom)
            )
    }
}

extension View {
    func photoCardTitle() -> some View {
        modifier(PhotoCardTitle())
    }
}
