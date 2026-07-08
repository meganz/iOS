import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

extension ContentUnavailableViewModel {
    static func transfersEmptyState(title: String) -> ContentUnavailableViewModel {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.newTransfersEmptyState,
            title: title,
            font: .body,
            titleTextColor: TokenColors.Text.secondary.swiftUI
        )
    }
}
