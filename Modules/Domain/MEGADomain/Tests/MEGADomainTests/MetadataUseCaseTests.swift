import MEGADomain
import MEGADomainMock
import XCTest

final class MetadataUseCaseTests: XCTestCase {
    func testCoordinateInTheFile_whenFileDoesNotExists_shouldReturnNil() {
        assert(url: sampleURL(), fileExists: false, coordinate: nil, fileType: .unknown)
    }

    func testCoordinateInTheFile_whenFileIsNotAAudioOrVideo_shouldReturnNil() {
        assert(
            url: sampleURL(),
            fileExists: true,
            coordinate: nil,
            fileType: .unknown,
            fileExtensionActions: [.isImage(sampleURL()), .isVideo(sampleURL())]
        )
    }

    func testCoordinateInTheFile_whenFileIsAImage_shouldReturnNilWhenCoordinateNotPresent() {
        assert(
            url: sampleURL(),
            fileExists: true,
            coordinate: nil,
            fileType: .image,
            fileExtensionActions: [.isImage(sampleURL())],
            metadataRepositoryActions: [.coordinateForImage(sampleURL())]
        )
    }

    func testCoordinateInTheFile_whenFileIsAVideo_shouldReturnNilWhenCoordinateNotPresent() {
        assert(
            url: sampleURL(),
            fileExists: true,
            coordinate: nil,
            fileType: .video,
            fileExtensionActions: [.isImage(sampleURL()), .isVideo(sampleURL())],
            metadataRepositoryActions: [.coordinateForVideo(sampleURL())]
        )
    }

    func testCoordinateInTheFile_whenFileIsAImage_shouldReturnValidCoordinateWhenCoordinatePresent() {
        assert(
            url: sampleURL(),
            fileExists: true,
            coordinate: Coordinate(latitude: 100, longitude: 100),
            fileType: .image,
            fileExtensionActions: [.isImage(sampleURL())],
            metadataRepositoryActions: [.coordinateForImage(sampleURL())]
        )
    }

    func testCoordinateInTheFile_whenFileIsAVideo_shouldReturnValidCoordinateWhenCoordinatePresent() {
        assert(
            url: sampleURL(),
            fileExists: true,
            coordinate: Coordinate(latitude: 100, longitude: 100),
            fileType: .video,
            fileExtensionActions: [.isImage(sampleURL()), .isVideo(sampleURL())],
            metadataRepositoryActions: [.coordinateForVideo(sampleURL())]
        )
    }

    func testFormatCoordinate_whenInvoked_shouldMatchTheResult() {
        let formattedString = "100&100"
        let metadataRepository = MockMetadataRepository(formattedString: formattedString)
        let sut = makeSUT(metadataRepository: metadataRepository)
        let coordinate = Coordinate(latitude: 100, longitude: 100)
        let result = sut.formatCoordinate(coordinate)
        XCTAssertEqual(metadataRepository.actions, [.formatCoordinate(coordinate)])
        XCTAssertEqual(result, formattedString)
    }

    // MARK: - Private methods.

    private typealias SUT = MetadataUseCase

    private func makeSUT(
        metadataRepository: some MetadataRepositoryProtocol = MockMetadataRepository(),
        fileSystemRepository: some FileSystemRepositoryProtocol = MockFileSystemRepository(),
        fileExtensionRepository: some FileExtensionRepositoryProtocol = MockFileExtensionRepository()
    ) -> SUT {
        SUT(
            metadataRepository: metadataRepository,
            fileSystemRepository: fileSystemRepository,
            fileExtensionRepository: fileExtensionRepository
        )
    }

    private func assert(
        url: URL,
        fileExists: Bool,
        coordinate: Coordinate?,
        fileType: MockFileExtensionRepository.FileType,
        fileExtensionActions: [MockFileExtensionRepository.Action] = [],
        metadataRepositoryActions: [MockMetadataRepository.Action] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let metadataRepository = MockMetadataRepository(coordinate: coordinate)
        let fileSystemRepository = MockFileSystemRepository(fileExists: fileExists)
        let fileExtensionRepository = MockFileExtensionRepository(fileType: fileType)
        let sut = makeSUT(
            metadataRepository: metadataRepository,
            fileSystemRepository: fileSystemRepository,
            fileExtensionRepository: fileExtensionRepository
        )
        let result = sut.coordinateInTheFile(at: url)
        XCTAssertEqual(result, coordinate, file: file, line: line)
        XCTAssertEqual(fileExtensionRepository.actions, fileExtensionActions, file: file, line: line)
        XCTAssertEqual(metadataRepository.actions, metadataRepositoryActions, file: file, line: line)
    }

    private func sampleURL() -> URL {
        URL(fileURLWithPath: "sample_image_with_gps.heic")
    }
}
