import SwiftUI

struct DisclosureIndicatorModifier: ViewModifier {
    @Environment(\.layoutDirection) var layoutDirection
    @Environment(\.colorScheme) var colorScheme
    private let discolureIndicator = "chevron.right"
    var color: Color?
    
    private var discolureIndicatorColor: Color {
        guard let color else {
            return colorScheme == .dark ?
                        Color(red: 0.92, green: 0.92, blue: 0.96).opacity(0.3) :
                        Color(red: 0.24, green: 0.24, blue: 0.26).opacity(0.3)
        }
        return color
    }
    
    func body(content: Content) -> some View {
        HStack {
            content
            
            Spacer()
            
            Image(systemName: discolureIndicator)
                .foregroundColor(discolureIndicatorColor)
                .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
        }
    }
}

public extension View {
    @ViewBuilder
    func addDisclosureIndicator(color: Color? = nil) -> some View {
        modifier(DisclosureIndicatorModifier(color: color))
    }
}
