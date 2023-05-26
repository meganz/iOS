import SwiftUI

public struct PlainFooterButtonView: View {
    let title: String
    let action: (() -> Void)
    
    @Environment(\.colorScheme) var colorScheme
    private var textColor: Color {
        colorScheme == .dark ? Color(red: 0, green: 0.76, blue: 0.60) : Color(red: 0, green: 0.65, blue: 0.52)
    }
    
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(textColor)
                .font(.footnote)
                .bold()
        }
    }
}
