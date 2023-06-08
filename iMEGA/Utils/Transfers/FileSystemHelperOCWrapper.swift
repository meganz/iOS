import MEGAData

@objc final class FileSystemHelperOCWrapper: NSObject {
    let fileSystemRepository = FileSystemRepository.newRepo
    
     @objc func documentsDirectory() -> URL {
        fileSystemRepository.documentsDirectory()
    }
}
