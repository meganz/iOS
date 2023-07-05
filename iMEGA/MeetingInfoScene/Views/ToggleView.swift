import SwiftUI

struct ToggleView: View {
    private enum Constants {
        static let viewHeight: CGFloat = 44
    }
    
    let image: String?
    let text: String
    @Binding var isOn: Bool

    var body: some View {
        VStack {
            Divider()
            HStack {
                if let image {
                    Image(image)
                }
                Toggle(text, isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.mnz_green00A886())))
            }
            .padding(.horizontal)
            Divider()
        }
        .frame(minHeight: Constants.viewHeight)
    }
}