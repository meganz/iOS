
import SwiftUI

struct TextWithToggleView: View {
    var text: String
    @Binding var toggle: Bool
    var body: some View {
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
