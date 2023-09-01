import MEGADomain
import MEGASdk

extension MEGABanner {
    var bannerEntity: BannerEntity? {
        guard let title = title,
              let description = description,
              let imageBaseURL = URL(string: imageLocationURLString ?? ""),
              let backgroundImageFilename = backgroundImageFilename,
              let imageFilename = imageFilename,
              let urlString = urlString
        else { return nil }

        return BannerEntity(
            identifier: Int(identifier),
            title: title,
            description: description,
            backgroundImageURL: imageBaseURL.appendingPathComponent(backgroundImageFilename),
            imageURL: imageBaseURL.appendingPathComponent(imageFilename),
            url: URL(string: urlString)
        )
    }
}
