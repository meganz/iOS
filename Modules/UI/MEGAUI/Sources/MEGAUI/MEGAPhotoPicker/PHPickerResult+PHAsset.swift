import PhotosUI
extension [PHPickerResult] {
    /// Converts an array of `PHPickerResult` objects to an array of `PHAsset` objects.
    func toPHAssets() -> [PHAsset] {
        let assetIdentifiers = compactMap(\.assetIdentifier)
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIdentifiers, options: nil)
        let assets: [PHAsset] = fetchResult.objects(at: IndexSet(0..<fetchResult.count))
        return assets
    }
}
