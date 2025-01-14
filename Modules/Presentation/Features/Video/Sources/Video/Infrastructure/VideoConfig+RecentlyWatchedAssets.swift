import SwiftUI

extension VideoConfig {
    
    public struct RecentlyWatchedAssets: Equatable, Sendable {
        let emptyView: EmptyView
        public init(
            emptyView: EmptyView
        ) {
            self.emptyView = emptyView
        }
        
        public struct EmptyView: Equatable, Sendable {
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
