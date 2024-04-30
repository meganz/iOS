import Foundation

enum InputCacheError: Error {
    case failedToDecodeJson
}

public enum InputCacheKeys: String {
    case version
    case sdkHash
    case sdkVersion
    case chatHash
    case chatVersion
    case releaseNotes
}

public func writeToCache(key: InputCacheKeys, value: String) {
    do {
        var cache = try decodeCache()
        cache[key.rawValue] = value
        try writeToURL(cache: cache)
    } catch {
        print("Non-fatal: failed to write \(key.rawValue):\(value) pair in cache.json with error \(String(describing: error))")
    }
}

public func readFromCache(key: InputCacheKeys) -> String? {
    do {
        let cache = try decodeCache()
        return cache[key.rawValue]
    } catch {
        print("Non-fatal: failed to read \(key.rawValue) from cache.json with error \(String(describing: error))")
        return nil
    }
}

private func decodeCache() throws -> [String: String] {
    try changeCurrentWorkDirectoryToRootDirectory()

    let cacheURL = try ensureCacheFile()
    let cacheData = try Data(contentsOf: cacheURL)
    let cache = try JSONSerialization.jsonObject(with: cacheData) as? [String: String]

    guard let cache else {
        throw InputCacheError.failedToDecodeJson
    }

    return cache
}

private let cacheURL = URL(fileURLWithPath: "scripts/ReleaseScripts/Resources/cache.json")

private func ensureCacheFile() throws -> URL {
    let fileManager = FileManager.default

    if !fileManager.fileExists(atPath: cacheURL.path) {
        fileManager.createFile(atPath: cacheURL.path, contents: nil, attributes: nil)
        let emptyCache: [String: String] = [:]
        try writeToURL(cache: emptyCache)
    }

    return cacheURL
}

private func writeToURL(cache: [String: String]) throws {
    let jsonData = try JSONSerialization.data(withJSONObject: cache, options: [])
    try jsonData.write(to: cacheURL, options: [])
}
