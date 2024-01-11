import SwiftUI

struct BadgeButtonSwfitUIWrapper: UIViewRepresentable {
    @Binding var text: String?
    @Binding var image: UIImage?

    init(text: Binding<String?>, image: Binding<UIImage?>) {
        self._text = text
        self._image = image
    }

    func makeUIView(context: Context) -> BadgeButton {
        BadgeButton()
    }

    func updateUIView(_ uiView: BadgeButton, context: Context) {
        if let image = self.image {
            uiView.setAvatarImage(image)
        }
        uiView.setBadgeText(text)
        return
    }
}
