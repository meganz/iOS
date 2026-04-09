import MEGAAssets
import MEGADesignToken
import SwiftUI

@MainActor
public struct TransferIndicatorView: View {
    private let action: (() -> Void)?
    private let previewState: TransferIndicatorViewState?

    public init(action: (() -> Void)? = nil) {
        self.action = action
        self.previewState = nil
    }

    init(state: TransferIndicatorViewState) {
        self.action = nil
        self.previewState = state
    }

    public var body: some View {
        if let previewState {
            TransferIndicatorContentView(state: previewState)
        } else {
            InternalTransferIndicatorView(
                viewModel: SharedTransferIndicator.viewModel,
                action: action
            )
        }
    }
}

private struct InternalTransferIndicatorView: View {
    @ObservedObject var viewModel: TransferIndicatorViewModel
    let action: (() -> Void)?

    var body: some View {
        if viewModel.isVisible {
            if let action {
                Button(action: action) {
                    TransferIndicatorContentView(state: viewModel.state)
                }
            } else {
                TransferIndicatorContentView(state: viewModel.state)
            }
        } else {
            EmptyView()
        }
    }
}

private struct TransferIndicatorContentView: View {
    let state: TransferIndicatorViewState
    private let indicatorSize: CGFloat = 24
    private let ringSize: CGFloat = 22

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    TokenColors.Icon.secondary.swiftUI.opacity(0.2),
                    style: StrokeStyle(lineWidth: 2)
                )
                .frame(width: ringSize, height: ringSize)

            Circle()
                .trim(from: 0, to: state.ringProgress)
                .stroke(
                    state.ringColor,
                    style: StrokeStyle(lineWidth: 2)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))

            if state.shouldTintIcon {
                state.icon
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
            } else {
                state.icon
                    .renderingMode(.original)
            }
        }
        .frame(width: indicatorSize, height: indicatorSize)
    }
}

#Preview {
    HStack(spacing: 16) {
        TransferIndicatorView(state: .inProgress(progress: 0))
        TransferIndicatorView(state: .inProgress(progress: 0.35))
        TransferIndicatorView(state: .completed)
        TransferIndicatorView(state: .error)
        TransferIndicatorView(state: .warning)
        TransferIndicatorView(state: .paused(progress: 0.5))
    }
    .padding()
    .background(TokenColors.Background.page.swiftUI)
}
