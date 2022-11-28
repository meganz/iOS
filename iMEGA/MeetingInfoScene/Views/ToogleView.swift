import SwiftUI

@available(iOS 14.0, *)
struct ToogleView: View {
    let image: String
    let text: String
    @Binding var isOn: Bool
    let valueChanged: ((Bool) -> Void)

    var body: some View {
        VStack {
            Divider()
            HStack {
                Image(image)
                Toggle(text, isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.mnz_green00A886())))
            }
            .padding(.horizontal)
            .onChange(of: isOn) { newValue in
                valueChanged(newValue)
            }
            Divider()
        }
        .frame(minHeight: 44)
    }
}

