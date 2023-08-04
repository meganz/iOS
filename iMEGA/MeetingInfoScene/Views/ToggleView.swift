import SwiftUI

struct ToggleView: View {
    private enum Constants {
        static let viewHeight: CGFloat = 44
    }
    
    let image: String?
    let text: String
    var enabled: Bool = true
    @Binding var isOn: Bool

    var body: some View {
        VStack {
            Divider()
            HStack {
                if let image {
                    Image(image)
                        .opacity(enabled ? 1.0 : 0.3)
                }
                Toggle(isOn: $isOn) {
                    Text(text)
                        .opacity(enabled ? 1.0 : 0.3)
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.mnz_green00A886())))
                .disabled(!enabled)
            }
            .padding(.horizontal)
            Divider()
        }
        .frame(minHeight: Constants.viewHeight)
    }
}
