import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

// MARK: - ContentState rendering

@available(iOS 16.2, *)
public extension TransferLiveActivityAttributes.ContentState {

    var statusIcon: Image {
        switch state {
        case .paused: MEGAAssets.Image.pauseSmallRegularSolid
        case .error: MEGAAssets.Image.alertCircleSmallRegularSolid
        case .overquota: MEGAAssets.Image.alertTriangleSmallRegularSolid
        case .completed: MEGAAssets.Image.checkSmallRegularOutline
        case .active:
            switch direction {
            case .mixed: MEGAAssets.Image.arrowUpDownSmallRegularOutline
            case .downloading: MEGAAssets.Image.arrowDownSmallReguarOutline
            case .uploading, .none: MEGAAssets.Image.arrowUpSmallReguarOutline
            }
        }
    }

    var tintColor: Color {
        switch state {
        case .active, .completed: TokenColors.Support.success.swiftUI
        case .paused: TokenColors.Icon.secondary.swiftUI
        case .error: TokenColors.Support.error.swiftUI
        case .overquota: TokenColors.Support.warning.swiftUI
        }
    }

    var statusIconTint: Color {
        switch state {
        case .error:
            TokenColors.Support.error.swiftUI
        case .overquota:
            TokenColors.Support.warning.swiftUI
        case .completed, .active, .paused:
            TokenColors.Icon.primary.swiftUI
        }
    }
}

// MARK: - View State

/// Resolves the staleness fork in a single place so the views never branch on
/// `isStale` themselves and just render bound values.
@available(iOS 16.2, *)
public struct TransferLiveActivityViewState {
    public let state: TransferLiveActivityAttributes.ContentState
    public let isStale: Bool

    public init(state: TransferLiveActivityAttributes.ContentState, isStale: Bool) {
        self.state = state
        self.isStale = isStale
    }

    public var statusIcon: Image {
        isStale ? MEGAAssets.Image.hourglassNewestSmallRegularOutline : state.statusIcon
    }

    public var statusText: String {
        isStale ? Strings.Localizable.Transfer.LiveActivity.openMEGAToResume : state.statusText
    }

    public var tintColor: Color {
        isStale ? TokenColors.Icon.secondary.swiftUI : state.tintColor
    }

    public var statusIconTint: Color {
        isStale ? TokenColors.Icon.secondary.swiftUI : state.statusIconTint
    }

    public var speed: String {
        isStale ? "" : state.formattedSpeed
    }

    public var progressFraction: Double { state.progressFraction }
    public var percentageText: String { state.percentageText }
    public var fileCountText: String { state.fileCountText }

    public var accessibilityDescription: String {
        [statusText, percentageText, fileCountText, speed]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    public var compactAccessibilityDescription: String {
        [statusText, percentageText]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
