import SwiftUI

/// Any configuration needed for video module assets, behaviour or styling
public struct VideoConfig: Equatable {
    
    public let rowAssets: RowAssets
    public let colorAssets: ColorAssets
    
    /// Configuration Dependencies that needs to be passed from Main module.
    /// - Parameters:
    ///   - rowAssets: contains assets for video row cell
    ///   - colorAssets: contains assets color assets
    public init(
        rowAssets: RowAssets,
        colorAssets: ColorAssets
    ) {
        self.rowAssets = rowAssets
        self.colorAssets = colorAssets
    }
    
    public struct RowAssets: Equatable {
        
        public let favoriteImage: UIImage?
        public let playImage: UIImage?
        public let dotSeparatorImage: UIImage?
        public let publicLinkImage: UIImage?
        public let moreImage: UIImage?
        public let labelAssets: LabelAssets
        
        /// Assets for Video cell view
        /// - Parameters:
        ///   - favoriteImage: Image for favorite icon
        ///   - playImage: Image for center play icon
        ///   - dotSeparatorImage: Image for dot separate icon
        ///   - publicLinkImage: Image for public link icon
        ///   - moreImage: Image for more icon
        ///   - labelAssets: Assets for labels
        public init(
            favoriteImage: UIImage?,
            playImage: UIImage?,
            dotSeparatorImage: UIImage?,
            publicLinkImage: UIImage?,
            moreImage: UIImage?,
            labelAssets: LabelAssets
        ) {
            self.favoriteImage = favoriteImage
            self.playImage = playImage
            self.dotSeparatorImage = dotSeparatorImage
            self.publicLinkImage = publicLinkImage
            self.moreImage = moreImage
            self.labelAssets = labelAssets
        }
        
        public struct LabelAssets: Equatable {
            
            public let redImage: UIImage?
            public let orangeImage: UIImage?
            public let yellowImage: UIImage?
            public let greenImage: UIImage?
            public let blueImage: UIImage?
            public let purpleImage: UIImage?
            public let greyImage: UIImage?

            /// Assets for label images is available for Dependency Injection. Later on, we can inject from Main module with  :
            /// NSString *labelString = [[MEGANode stringForNodeLabel:node.label] stringByAppendingString:@"Small"];
            /// UIImage? *redImage = [UIImage? imageNamed:labelString];
            /// - Parameters:
            ///   - redImage: image for red label icon
            ///   - orangeImage: image for orange label icon
            ///   - yellowImage: image for yellow label icon
            ///   - greenImage: image for green label icon
            ///   - blueImage: image for blue label icon
            ///   - purpleImage: image for purple label icon
            ///   - greyImage: image for grey label icon
            public init(
                redImage: UIImage?,
                orangeImage: UIImage?,
                yellowImage: UIImage?,
                greenImage: UIImage?,
                blueImage: UIImage?,
                purpleImage: UIImage?,
                greyImage: UIImage?
            ) {
                self.redImage = redImage
                self.orangeImage = orangeImage
                self.yellowImage = yellowImage
                self.greenImage = greenImage
                self.blueImage = blueImage
                self.purpleImage = purpleImage
                self.greyImage = greyImage
            }
        }
    }
    
    public struct ColorAssets: Equatable {
        
        public let primaryTextColor: Color
        public let secondaryTextColor: Color
        public let tertiaryGreyColor: Color
        public let whiteColor: Color
        public let durationTextBackgroundColor: Color
        
        /// Specify colors that needs to be injected from Main module.
        public init(
            primaryTextColor: Color,
            secondaryTextColor: Color,
            tertiaryGreyBackgroundColor: Color,
            whiteColor: Color,
            durationTextBackgroundColor: Color
        ) {
            self.primaryTextColor = primaryTextColor
            self.secondaryTextColor = secondaryTextColor
            self.tertiaryGreyColor = tertiaryGreyBackgroundColor
            self.whiteColor = whiteColor
            self.durationTextBackgroundColor = durationTextBackgroundColor
        }
    }
}
