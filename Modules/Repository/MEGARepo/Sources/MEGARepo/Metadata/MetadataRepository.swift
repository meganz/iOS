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
              var latitude = dictionary["Latitude"] as? Double,
              var longitude = dictionary["Longitude"] as? Double,
              let latitudeRef = dictionary["LatitudeRef"] as? String,
              let longitudeRef = dictionary["LongitudeRef"] as? String else {
            return nil
        }

        if latitudeRef == "S" {
            latitude = -latitude
        }
        if longitudeRef == "W" {
            longitude = -longitude
        }
        return Coordinate(latitude: latitude, longitude: longitude)
    }

    public func coordinateForVideo(at url: URL) async -> Coordinate? {
        let asset = AVAsset(url: url)
        guard let metadata = try? await asset.load(.metadata) else { return nil }
        for item in metadata where item.key?.isEqual(AVMetadataKey.quickTimeMetadataKeyLocationISO6709) == true {
            do {
                /// Location description will look something like "+13.0716+074.9953+114.877/". we need to extract the latitude and longitude from the string.
                if let locationDescription = try await item.load(.stringValue),
                   let latitude = Double(String(locationDescription.prefix(8))),
                   case let start = locationDescription.index(locationDescription.startIndex, offsetBy: 8),
                   case let end = locationDescription.index(locationDescription.startIndex, offsetBy: 17),
                   let longitude = Double(String(locationDescription[start..<end])) {
                    return Coordinate(latitude: latitude, longitude: longitude)
                }
            } catch {
                return nil
            }
        }

        return nil
    }

    public func formatCoordinate(_ coordinate: Coordinate) -> String {
        ">setCoordinates=\(coordinate.latitude)&\(coordinate.longitude)"
    }
}
