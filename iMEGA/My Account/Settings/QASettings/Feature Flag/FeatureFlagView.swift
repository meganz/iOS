import MEGADesignToken
import MEGADomain
import SwiftUI

struct FeatureFlagView: View {
    
    @StateObject var viewModel: FeatureFlagViewModel = FeatureFlagViewModel()
    
    var body: some View {
        ForEach(viewModel.featureFlagList.indices, id: \.self) { index in
            Toggle(
                viewModel.featureFlagList[index].name,
                isOn: $viewModel.featureFlagList[index].isEnabled.onChange { _ in
                    Task { @MainActor in
                        viewModel.saveFeatureFlag(featureFlag: viewModel.featureFlagList[index])
                    }
                }
            )
            .padding(.horizontal)
            .padding(.vertical, 5)
            .listRowInsets(EdgeInsets())
            .foregroundColor(TokenColors.Text.primary.swiftUI)
        }
    }
}
