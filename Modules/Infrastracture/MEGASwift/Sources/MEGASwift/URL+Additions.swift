import Foundation

public extension URL {
    var attributes: [FileAttributeKey: Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch {
            return nil
        }
    }
}

// MARK: - URL + FileExtensionGroupDataSource
extension URL: FileExtensionGroupDataSource {
    public static var fileExtensionPath: KeyPath<URL, String> { \.lastPathComponent.pathExtension }
}
