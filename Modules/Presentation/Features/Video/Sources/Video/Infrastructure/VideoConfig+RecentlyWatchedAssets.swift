import SwiftUI

extension VideoConfig {
    
    public struct RecentlyWatchedAssets: Equatable {
        let emptyView: EmptyView
        public init(
            emptyView: EmptyView
        ) {
            self.emptyView = emptyView
        }
        
        public struct EmptyView: Equatable {
            let recentsEmptyStateImage: UIImage
            
            public init(
                recentsEmptyStateImage: UIImage
            ) {
                self.recentsEmptyStateImage = recentsEmptyStateImage
            }
        }
    }
}

extension VideoConfig {
    var recentsEmptyStateImage: UIImage { recentlyWatchedAssets.emptyView.recentsEmptyStateImage }
}
