import Foundation
import SwiftUI

enum PhotoLibraryConstants {
    static let cardMinimumWidth: CGFloat = 300
    static let cardMaximumWidth: CGFloat = 1000
    static let cardHeight: CGFloat = 250
    static let cardRowPadding: CGFloat = 16
    static let libraryPadding: CGFloat = 16
    static let scrollViewCoordinateSpaceName = "scrollView"
    
    static let cardColumns = [
        GridItem(
            .adaptive(minimum: PhotoLibraryConstants.cardMinimumWidth,
                      maximum: PhotoLibraryConstants.cardMaximumWidth)
        )
    ]
}

public extension Notification.Name {
    static let didFinishPhotoCardScrollPositionCalculation = Notification.Name("didFinishCardScrollPositionCalculation")
    static let didPhotoFavouritesChange = Notification.Name("didPhotoFavouritesChange")
}
 
