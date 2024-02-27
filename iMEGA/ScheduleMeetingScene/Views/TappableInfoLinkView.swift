import SwiftUI

// This view will highlight text surrounded with [A]...[/A] tags and, style it and make it tappable
struct TappableInfoLinkView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let copy: String
    let foregroundColor: (ColorScheme) -> Color
    let backgroundColor: (ColorScheme) -> Color
    let linkColor: (ColorScheme) -> UIColor
    let action: (() -> Void)
    
    var body: some View {
        VStack(spacing: 0) {
            TaggableText(copy, linkColor: linkColor)
            .font(.footnote)
            .foregroundStyle(foregroundColor(colorScheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 6)
            .padding(.bottom, 20)
        }
        .frame(minHeight: 53.0)
        .background(backgroundColor(colorScheme))
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}
