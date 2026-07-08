import SwiftUI

struct SubscriptionProFeature: Identifiable {
    var id: String { title }
    let icon: Image
    let title: String

    init(icon: Image, title: String) {
        self.icon = icon
        self.title = title
    }
}
