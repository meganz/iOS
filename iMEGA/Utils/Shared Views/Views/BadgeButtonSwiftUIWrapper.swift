import MEGAUIKit
import SwiftUI

struct BadgeButtonSwfitUIWrapper: UIViewRepresentable {
    @Binding var text: String?
    @Binding var image: UIImage?
    private let action: () -> Void

    init(text: Binding<String?>, image: Binding<UIImage?>, action: @escaping () -> Void) {
        self._text = text
        self._image = image
        self.action = action
    }

    func makeUIView(context: Context) -> BadgeButton {
        BadgeButton(action: action)
    }

    func updateUIView(_ uiView: BadgeButton, context: Context) {
        if let image = self.image {
            uiView.setAvatarImage(image)
        }
        uiView.setBadgeText(text)
        return
    }
}
