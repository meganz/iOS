import SwiftUI

public struct TextWithToggleView: View {
    var text: String
    @Binding var toggle: Bool
    
    public init(text: String, toggle: Binding<Bool>) {
        self.text = text
        _toggle = toggle
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            Divider()
            Toggle(isOn: $toggle) {
                Text(text)
            }
            .padding(.horizontal)
            Divider()
        }
        .background(Color(.systemBackground))
    }
}
