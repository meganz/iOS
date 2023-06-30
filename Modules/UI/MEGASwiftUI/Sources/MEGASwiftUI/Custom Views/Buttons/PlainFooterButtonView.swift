import SwiftUI

public struct PlainFooterButtonView: View {
    private let title: String
    @Binding private var didTapButton: Bool
    
    @Environment(\.colorScheme) var colorScheme
    private var textColor: Color {
        colorScheme == .dark ? Color(red: 0, green: 0.76, blue: 0.60) : Color(red: 0, green: 0.65, blue: 0.52)
    }
    
    public init(title: String, didTapButton: Binding<Bool>) {
        self.title = title
        self._didTapButton = didTapButton
    }
    
    public var body: some View {
        Button {
            didTapButton = true
        } label: {
            Text(title)
                .foregroundColor(textColor)
                .font(.footnote)
                .bold()
        }
    }
}
