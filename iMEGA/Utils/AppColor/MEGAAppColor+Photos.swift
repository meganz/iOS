import MEGADesignToken
import MEGAPresentation
import SwiftUI
import UIKit

extension MEGAAppColor {
    enum Photos {
        case cameraUploadStatusUploading
        case cameraUploadStatusCompleted
        case decryptTitleEnabled
        case decryptTitleDisabled
        case filterBackground
        case filterLocationItemBackground
        case filterLocationItemForeground
        case filterLocationItemTickForeground
        case filterNormalTextForeground
        case filterTextForeground
        case filterTypeNormalBackground
        case filterTypeSelectionBackground
        case filterTypeSelectionForeground
        case pageTabForeground
        case photoNumbersBackground
        case photoSelectionBorder
        case rightBarButtonForeground
        case zoomButtonForeground
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case .cameraUploadStatusUploading: TokenColors.Background.blur
            case .cameraUploadStatusCompleted: TokenColors.Background.blur
            case .decryptTitleEnabled: TokenColors.Background.blur
            case .decryptTitleDisabled: TokenColors.Background.blur
            case .filterBackground: TokenColors.Background.blur
            case .filterLocationItemBackground: TokenColors.Background.blur
            case .filterLocationItemForeground: TokenColors.Text.primary
            case .filterLocationItemTickForeground: TokenColors.Text.primary
            case .filterNormalTextForeground: TokenColors.Text.primary
            case .filterTextForeground: TokenColors.Text.primary
            case .filterTypeNormalBackground: TokenColors.Background.blur
            case .filterTypeSelectionBackground: TokenColors.Background.blur
            case .filterTypeSelectionForeground: TokenColors.Text.primary
            case .pageTabForeground: TokenColors.Text.primary
            case .photoNumbersBackground: TokenColors.Background.blur
            case .photoSelectionBorder: TokenColors.Background.blur
            case .rightBarButtonForeground: TokenColors.Text.primary
            case .zoomButtonForeground: TokenColors.Text.primary
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case .cameraUploadStatusUploading: UIColor.cameraUploadStatusUploading
            case .cameraUploadStatusCompleted: UIColor.cameraUploadStatusCompleted
            case .decryptTitleEnabled: UIColor.mediaConsumptionDecryptTitleEnabled
            case .decryptTitleDisabled: UIColor.mediaConsumptionDecryptTitleDisabled
            case .filterBackground: UIColor.photosFilterBackground
            case .filterLocationItemBackground: UIColor.photosFilterLocationItemBackground
            case .filterLocationItemForeground: UIColor.photosFilterLocationItemForeground
            case .filterLocationItemTickForeground: UIColor.photosFilterLocationItemTickForeground
            case .filterNormalTextForeground: UIColor.photosFilterNormalTextForeground
            case .filterTextForeground: UIColor.photosFilterTextForeground
            case .filterTypeNormalBackground: UIColor.photosFilterTypeNormalBackground
            case .filterTypeSelectionBackground: UIColor.photosFilterTypeSelectionBackground
            case .filterTypeSelectionForeground: UIColor.photosFilterTypeSelectionForeground
            case .pageTabForeground: UIColor.photosPageTabForeground
            case .photoNumbersBackground: UIColor.mediaConsumptionPhotoNumbersBackground
            case .photoSelectionBorder: UIColor.photosPhotoSeletionBorder
            case .rightBarButtonForeground: UIColor.photosRightBarButtonForeground
            case .zoomButtonForeground: UIColor.photosZoomButtonForeground
            }
        }
    }
}
