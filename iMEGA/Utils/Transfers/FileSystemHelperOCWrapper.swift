import MEGARepo

@objc final class FileSystemHelperOCWrapper: NSObject {
    let fileSystemRepository = FileSystemRepository.sharedRepo
    
     @objc func documentsDirectory() -> URL {
        fileSystemRepository.documentsDirectory()
    }
}
