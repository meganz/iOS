import Combine
import MEGADesignToken
import SwiftUI

public struct RequestStatusProgressView: View {
    @StateObject var viewModel: RequestStatusProgressViewModel
    
    public init(viewModel: @autoclosure @escaping () -> RequestStatusProgressViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        ProgressView(value: viewModel.progress, total: viewModel.total)
            .tint(TokenColors.Button.brand.swiftUI)
            .background(TokenColors.Background.surface2.swiftUI)
            .opacity(viewModel.opacity)
            .task {
                await viewModel.getRequestStatsProgress()
            }
    }
}
