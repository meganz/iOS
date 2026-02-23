import SwiftUI

// IOS-11343: Fetch banners and display them
@MainActor
final class PromotionalBannersWidgetViewModel: ObservableObject {
    @Published var bannerInputs: [PromotionBannerInput] = [.test, .test]
}
