import MEGADomain
import MEGADomainMock
import XCTest

final class CameraUploadsUseCaseTests: XCTestCase {
    var repository: MockCameraUploadsRepository!
    var sut: CameraUploadsUseCase<MockCameraUploadsRepository>!

    override func setUp() {
        super.setUp()
        
        repository = MockCameraUploadsRepository.newRepo
        sut = CameraUploadsUseCase(cameraUploadsRepository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        
        super.tearDown()
    }
    
    func testCameraUploadsNode_defaultValues_returnsCameraUploadsNode() async throws {
        let expectedNodeName = "Camera Uploads"
        let result = try await sut.cameraUploadsNode()
        XCTAssertEqual(result.name, expectedNodeName)
    }

    func testRegisterCameraUploadsBackup_defaultValues_returnsCameraUploadsHandle() async throws {
        let expectedHandle = HandleEntity(1)
        let result = try await sut.registerCameraUploadsBackup("TestNode")
        XCTAssertEqual(result, expectedHandle)
    }

    func testIsCameraUploadsNode_defaultValues_returnsFalse() async throws {
        let falseResult = try await sut.isCameraUploadsNode(handle: HandleEntity(2))
        XCTAssertFalse(falseResult)
    }
}
