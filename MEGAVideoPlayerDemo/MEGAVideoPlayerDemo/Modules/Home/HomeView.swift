import MEGAUIComponent
import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Logged in")
            MEGAButton("Logout") {
                Task { await viewModel.logout() }
            }
            .padding(16)
        }
    }
}

#Preview {
    HomeView(viewModel: .liveValue)
}
