import CoreGraphics
import MEGAAssets
import MEGADesignToken
import SwiftUI

enum TransferIndicatorViewState: Equatable, Sendable {
    case initial
    case inProgress(progress: CGFloat)
    case completed
    case error
    case warning
    case paused(progress: CGFloat)

    var shouldTintIcon: Bool {
        switch self {
        case .initial, .inProgress, .paused:
            true
        case .completed, .error, .warning:
            false
        }
    }

    var icon: Image {
        switch self {
        case .initial:
            MEGAAssets.Image.transferIndicator
        case .inProgress:
            MEGAAssets.Image.transferIndicator
        case .completed:
            MEGAAssets.Image.transferSuccess
        case .error:
            MEGAAssets.Image.transferError
        case .warning:
            MEGAAssets.Image.transferWarning
        case .paused:
            MEGAAssets.Image.transferPause
        }
    }

    var ringColor: Color {
        switch self {
        case .initial, .inProgress, .completed:
            TokenColors.Support.success.swiftUI
        case .error:
            TokenColors.Support.error.swiftUI
        case .warning:
            TokenColors.Support.warning.swiftUI
        case .paused:
            TokenColors.Icon.secondary.swiftUI
        }
    }

    var ringProgress: CGFloat {
        switch self {
        case .initial:
            0
        case .inProgress(let progress), .paused(let progress):
            max(0, min(progress, 1))
        case .completed:
            0
        case .error, .warning:
            1
        }
    }
}
