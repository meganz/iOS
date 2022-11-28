import SwiftUI

@available(iOS 14.0, *)
struct MeetingLinkToogleView: View {
    let image: String
    let text: String
    @Binding var disabled: Bool
    @Binding var isOn: Bool
    let valueChanged: ((Bool) -> Void)
    let action: (() -> Void)

    var body: some View {
        VStack {
            ToogleView(image: image, text: text, isOn: $isOn, valueChanged: valueChanged)
                .disabled(disabled)
            if isOn {
                Button {
                    action()
                } label: {
                    Text(Strings.Localizable.Meetings.Action.shareLink)
                        .padding(.horizontal)
                        .foregroundColor(Color(UIColor.mnz_green00A886()))
                }
                Divider()
            }
        }
    }
}
