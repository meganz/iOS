import MEGADomain
import MEGADomainMock
import XCTest

final class MetadataUseCaseTests: XCTestCase {
    private let sampleCoordinate = Coordinate(latitude: 100, longitude: 100)
    
    func testCoordinateInTheFile_whenFileDoesNotExists_shouldReturnNil() async {
        await assert(url: sampleURL(), fileExists: false, coordinate: nil, fileType: .unknown)
    }

    func testCoordinateInTheFile_whenFileIsNotAAudioOrVideo_shouldReturnNil() async {
        await assert(
            url: sampleURL(),
            fileExists: true,
            coordinate: nil,
            fileType: .unknown,
            fileExtensionActions: [.isImage(sampleURL()), .isVideo(sampleURL())]
        )
    }

    func testCoordinateInTheFile_whenFileIsAImage_shouldReturnNilWhenCoordinateNotPresent() async {
        await assert(
            url: sampleURL(),
            fileExists: true,
            coordinate: nil,
            fileType: .image,
            fileExtensionActions: [.isImage(sampleURL())],
            metadataRepositoryActions: [.coordinateForImage(sampleURL())]
        )
    }

    func testCoordinateInTheFile_whenFileIsAVideo_shouldReturnNilWhenCoordinateNotPresent() async {
        await assert(
            url: sampleURL(),
            fileExists: true,
            coordinate: nil,
            fileType: .video,
            fileExtensionActions: [.isImage(sampleURL()), .isVideo(sampleURL())],
            metadataRepositoryActions: [.coordinateForVideo(sampleURL())]
        )
    }

    func testCoordinateInTheFile_whenFileIsAImage_shouldReturnValidCoordinateWhenCoordinatePresent() async {
        await assert(
            url: sampleURL(),
            fileExists: true,
            coordinate: sampleCoordinate,
            formattedCoordinate: "valid_formattedCoordinate",
            fileType: .image,
            fileExtensionActions: [.isImage(sampleURL())],
            metadataRepositoryActions: [
                .coordinateForImage(sampleURL()),
                .formatCoordinate(sampleCoordinate)
            ]
        )
    }

    func testCoordinateInTheFile_whenFileIsAVideo_shouldReturnValidCoordinateWhenCoordinatePresent() async {
        await assert(
            url: sampleURL(),
            fileExists: true,
            coordinate: sampleCoordinate,
            formattedCoordinate: "valid_formattedCoordinate",
            fileType: .video,
            fileExtensionActions: [.isImage(sampleURL()), .isVideo(sampleURL())],
            metadataRepositoryActions: [
                .coordinateForVideo(sampleURL()),
                .formatCoordinate(sampleCoordinate)
            ]
        )
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
        formattedCoordinate: String? = nil,
        fileType: MockFileExtensionRepository.FileType,
        fileExtensionActions: [MockFileExtensionRepository.Action] = [],
        metadataRepositoryActions: [MockMetadataRepository.Action] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let metadataRepository = if let formattedCoordinate {
            MockMetadataRepository(coordinate: coordinate, formattedString: formattedCoordinate)
        } else {
            MockMetadataRepository(coordinate: coordinate)
        }
        let fileSystemRepository = MockFileSystemRepository(fileExists: fileExists)
        let fileExtensionRepository = MockFileExtensionRepository(fileType: fileType)
        let sut = makeSUT(
            metadataRepository: metadataRepository,
            fileSystemRepository: fileSystemRepository,
            fileExtensionRepository: fileExtensionRepository
        )
        let result = await sut.formattedCoordinate(forFileURL: url)
        XCTAssertEqual(result, formattedCoordinate, file: file, line: line)
        XCTAssertEqual(fileExtensionRepository.actions, fileExtensionActions, file: file, line: line)
        XCTAssertEqual(metadataRepository.actions, metadataRepositoryActions, file: file, line: line)
        XCTAssertEqual(metadataRepository.actions, metadataRepositoryActions, file: file, line: line)
    }

    private func sampleURL() -> URL {
        URL(fileURLWithPath: "sample_image_with_gps.heic")
    }
}
