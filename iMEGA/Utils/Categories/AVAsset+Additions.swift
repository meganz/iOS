public enum DynamicAttribute: String {
    case commonMetadata
    case metadata
}


public extension AVAsset {

    private func loadAttributeAsynchronously(_ attribute: DynamicAttribute, completion: (() -> Void)?) {
        
        loadValuesAsynchronously(forKeys: [attribute.rawValue], completionHandler: completion)
    }

    private func loadedAttributeValue<T>(for attribute: DynamicAttribute) -> T? {
        var error : NSError?
        let status = statusOfValue(forKey: attribute.rawValue, error: &error)
 
        guard error == nil, (status == .loaded) else { return nil }

        return value(forKey: attribute.rawValue) as? T
    }

    func load(_ attribute: DynamicAttribute, completion: @escaping ((_ items: [AVMetadataItem]) -> Void)) {
        loadAttributeAsynchronously(attribute) {
            let metadataItems = self.loadedAttributeValue(for: attribute) as [AVMetadataItem]?
            DispatchQueue.main.async {
                completion(metadataItems ?? [])
            }
        }
    }
    
    func loadMetadata(completion: @escaping ((_ name: String?, _ artist: String?, _ album: String?, _ artwork: Data?) -> Void)) {
        
        loadAttributeAsynchronously(.commonMetadata) {
            guard let metadata = self.loadedAttributeValue(for: .commonMetadata) as [AVMetadataItem]? else {
                DispatchQueue.main.async {
                    completion(nil, nil, nil, nil)
                }
                return
            }
            
            completion(metadata.first { $0.commonKey == AVMetadataKey.commonKeyTitle }?.value as? String,
                       metadata.first { $0.commonKey == AVMetadataKey.commonKeyArtist }?.value as? String,
                       metadata.first { $0.commonKey == AVMetadataKey.commonKeyAlbumName }?.value as? String,
                       metadata.first { $0.commonKey == AVMetadataKey.commonKeyArtwork }?.value as? Data)
        }
    }
}
