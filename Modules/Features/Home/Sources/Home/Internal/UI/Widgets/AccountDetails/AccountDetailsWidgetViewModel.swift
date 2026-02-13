import Combine
import SwiftUI

// [IOS-11315]: Implement the logic to populate user data
@MainActor
final class AccountDetailsWidgetViewModel: ObservableObject {
    @Published var userName: String
    @Published var plan: String
    @Published var profilePicture: Image
    @Published var storageUsage: String
    @Published var storageUsedFraction: Double

    var storageUsedFractionColor: Color {
        if storageUsedFraction < 0.5 {
            .blue
        } else if storageUsedFraction < 0.75 {
            .yellow
        } else { .red }
    }

    init() {
        userName = "Mike"
        plan = "Free"
        profilePicture = Image(systemName: "person.crop.circle.fill")
        storageUsage = "10GB of 20GB used"
        storageUsedFraction = 0.9
    }
}
