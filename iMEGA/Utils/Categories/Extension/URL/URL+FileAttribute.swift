
extension URL {
    var attributes: [FileAttributeKey : Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            MEGALogError("FileAttribute error: \(error)")
        }
        return nil
    }
}
