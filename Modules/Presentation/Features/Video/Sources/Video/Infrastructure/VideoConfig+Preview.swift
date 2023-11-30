#if DEBUG
import MEGASwiftUI
import SwiftUI

extension VideoConfig {
    
    /// Internal Video SPM module Dependencies helper for SwiftUI
    static let preview = VideoConfig(
        rowAssets: RowAssets(
            favoriteImage: UIImage(systemName: "heart.fill"),
            playImage: UIImage(systemName: "play.circle.fill"),
            dotSeparatorImage: UIImage(systemName: "circle.fill"),
            publicLinkImage: UIImage(systemName: "link"),
            moreImage: UIImage(systemName: "ellipsis"),
            labelAssets: RowAssets.LabelAssets(
                redImage: .withColor(.systemRed, size: CGSize(width: 12, height: 12)),
                orangeImage: .withColor(.systemOrange, size: CGSize(width: 12, height: 12)),
                yellowImage: .withColor(.systemYellow, size: CGSize(width: 12, height: 12)),
                greenImage: .withColor(.systemGreen, size: CGSize(width: 12, height: 12)),
                blueImage: .withColor(.systemBlue, size: CGSize(width: 12, height: 12)),
                purpleImage: .withColor(.systemPurple, size: CGSize(width: 12, height: 12)),
                greyImage: .withColor(.systemGray, size: CGSize(width: 12, height: 12))
            )
        ),
        colorAssets: ColorAssets(
            primaryTextColor: .primary,
            secondaryTextColor: .secondary,
            tertiaryGreyBackgroundColor: Color(red: 0.32, green: 0.32, blue: 0.32),
            whiteColor: .white,
            durationTextBackgroundColor: Color(red: 0.09, green: 0.09, blue: 0.09).opacity(0.5)
        )
    )
}
#endif
