@testable import MEGA
import Testing

struct MEGAProcessAssetTests {
    @Test
    func test_noConflict_returnsOriginalPath() {
        let processor = MEGAProcessAsset()
        let originalPath = "/Documents/image.png"
        let allPaths = ["/Documents/other.png"]

        let result = processor.generateUniqueFilePath(from: originalPath, allFilePaths: allPaths)

        #expect(result == originalPath)
    }

    @Test
    func test_conflictWithIncrementingSuffix_returnsNextAvailablePath() {
        let processor = MEGAProcessAsset()
        let originalPath = "/Documents/image.png"
        let allPaths = [
            "/Documents/image.png",
            "/Documents/image_1.png",
            "/Documents/image_2.png"
        ]

        let result = processor.generateUniqueFilePath(from: originalPath, allFilePaths: allPaths)

        #expect(result == "/Documents/image_3.png")
    }

    @Test
    func test_noExtensionWithConflicts_returnsIncrementedName() {
        let processor = MEGAProcessAsset()
        let originalPath = "/Documents/archive"
        let allPaths = [
            "/Documents/archive",
            "/Documents/archive_1",
            "/Documents/archive_2"
        ]

        let result = processor.generateUniqueFilePath(from: originalPath, allFilePaths: allPaths)

        #expect(result == "/Documents/archive_3")
    }

    @Test
    func test_multipleDotsInFilename_returnsIncrementedBeforeExtension() {
        let processor = MEGAProcessAsset()
        let originalPath = "/Documents/my.archive.tar.gz"
        let allPaths = [
            "/Documents/my.archive.tar.gz",
            "/Documents/my.archive.tar_1.gz"
        ]

        let result = processor.generateUniqueFilePath(from: originalPath, allFilePaths: allPaths)

        #expect(result == "/Documents/my.archive.tar_2.gz")
    }

    @Test
    func test_gapInSuffixes_returnsLowestAvailableIndex() {
        let processor = MEGAProcessAsset()
        let originalPath = "/Documents/my.archive.tar.gz"
        let allPaths = [ "/Documents/my.archive.tar.gz", "/Documents/my.archive.tar_2.gz"]

        let result = processor.generateUniqueFilePath(from: originalPath, allFilePaths: allPaths)

        #expect(result == "/Documents/my.archive.tar_1.gz")
    }
}
