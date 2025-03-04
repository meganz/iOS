import AVFoundation
import Foundation
import MEGADomain

public final class MetadataRepository: MetadataRepositoryProtocol {
    public init() {}

    public func coordinateForImage(at url: URL) -> Coordinate? {
        guard let imageData = try? Data(contentsOf: url),
              let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let dictionary = imageProperties[kCGImagePropertyGPSDictionary] as? [String: AnyObject],
              let latitude = dictionary["Latitude"] as? Double,
              let longitude = dictionary["Longitude"] as? Double else {
            return nil
        }

        return Coordinate(latitude: latitude, longitude: longitude)
    }

    public func coordinateForVideo(at url: URL) async -> Coordinate? {
        let asset = AVAsset(url: url)
        guard let metadata = try? await asset.load(.metadata) else { return nil }
        for item in metadata {
            if item.key?.isEqual(AVMetadataKey.quickTimeMetadataKeyLocationISO6709) == true,
               let locationDescription = item.stringValue,
               /// Location description will look something like "+13.0716+074.9953+114.877/". we need to extract the latitude and longitude from the string.
               let latitude = Double(String(locationDescription.prefix(8))),
               case let start = locationDescription.index(locationDescription.startIndex, offsetBy: 8),
               case let end = locationDescription.index(locationDescription.startIndex, offsetBy: 17),
               let longitude = Double(String(locationDescription[start..<end])) {
                return Coordinate(latitude: latitude, longitude: longitude)
            }
        }

        return nil
    }

    public func formatCoordinate(_ coordinate: Coordinate) -> String {
        ">setCoordinates=\(coordinate.latitude)&\(coordinate.longitude)"
    }
}
