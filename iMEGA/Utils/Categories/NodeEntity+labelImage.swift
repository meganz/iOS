import MEGAAssets
import MEGADomain

extension NodeEntity {
    var labelImage: UIImage {
        switch label {
        case .unknown:
            MEGAAssets.UIImage.filetypeFolder
        case .red:
            MEGAAssets.UIImage.redFolder
        case .orange:
            MEGAAssets.UIImage.orangeFolder
        case .yellow:
            MEGAAssets.UIImage.yellowFolder
        case .green:
            MEGAAssets.UIImage.greenFolder
        case .blue:
            MEGAAssets.UIImage.blueFolder
        case .purple:
            MEGAAssets.UIImage.purpleFolder
        case .grey:
            MEGAAssets.UIImage.greyFolder
        }
    }
}
