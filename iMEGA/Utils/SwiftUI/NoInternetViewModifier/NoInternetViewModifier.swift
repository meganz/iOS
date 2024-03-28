import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import SwiftUI

struct NoInternetViewModifier: ViewModifier {
    @StateObject private var viewModel: NoInternetViewModel

    init(
        viewModel: NoInternetViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    func body(content: Content) -> some View {
        Group {
            if viewModel.isConnected {
                content
            } else {
                noInternetConnectionView
            }
        }
        .task {
            await viewModel.onTask()
        }
    }

    private var noInternetConnectionView: some View {
        VStack {
            Image(.noInternetEmptyState)
            Text(Strings.Localizable.noInternetConnection)
                .font(.headline.weight(.regular))
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }
        .padding(.bottom, 70)
    }
}

extension View {
    /// Applies the `NoInternetViewModifier` to the view, simplifying its usage.
    ///
    /// This method provides a convenient way to apply the `NoInternetViewModifier` to a SwiftUI view.
    ///
    /// - Parameters:
    ///   - viewModel: ViewModel for the modifier. Defaults to an instance of `NoInternetViewModel` with `networkConnectionStateChanged` set to nil.
    ///
    /// - Returns: A view modified to display no-internet when there is no internet connection.
    ///
    /// - Example Usage:
    ///   ```swift
    ///   MyContentView()
    ///       .noInternetViewModifier()
    ///   ```
    ///
    func noInternetViewModifier(
        viewModel: NoInternetViewModel = NoInternetViewModel(
            networkMonitorUseCase: NetworkMonitorUseCase(
                repo: NetworkMonitorRepository.newRepo
            )
        )
    ) -> some View {
        modifier(NoInternetViewModifier(viewModel: viewModel))
    }
}

#Preview {
    Text("Hello world")
        .noInternetViewModifier()
}
