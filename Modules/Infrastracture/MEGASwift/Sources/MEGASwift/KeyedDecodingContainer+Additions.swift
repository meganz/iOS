import Foundation

extension KeyedDecodingContainer {
    public func decodeIfPresent<T>(for key: KeyedDecodingContainer<K>.Key) throws -> T? where T: Decodable {
        try decodeIfPresent(T.self, forKey: key)
    }
}
