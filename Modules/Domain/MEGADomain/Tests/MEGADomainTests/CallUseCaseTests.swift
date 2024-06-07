import MEGADomain
import MEGADomainMock
import XCTest

final class CallUseCaseTests: XCTestCase {
    class Harness {
        enum TestError: Error {
            case anyError
        }
        let sut: CallUseCase<MockCallRepository>
        let repo = MockCallRepository()
        init(throws: Bool = false) {
            if `throws` {
                repo.errorToThrow = TestError.anyError
            }
            self.sut = .init(repository: repo)
        }

    }
    
    func testRaiseHand_Success() async throws {
        let harness = Harness()
        try await harness.sut.raiseHand(forCall: .testEntity())
        XCTAssertEqual(harness.repo.raiseHandCalls.map(\.uuid), [.testUUID])
    }
    
    func testRaiseHand_Throws() async throws {
        let harness = Harness(throws: true)
        do {
            try await harness.sut.raiseHand(forCall: .testEntity())
            XCTFail("Should throw and go catch ")
        } catch {}
    }
    
    func testLowerHand_Success() async throws {
        let harness = Harness()
        try await harness.sut.lowerHand(forCall: .testEntity())
        XCTAssertEqual(harness.repo.lowerHandCalls.map(\.uuid), [.testUUID])
    }
    
    func testLowerHand_Throws() async throws {
        let harness = Harness(throws: true)
        do {
            try await harness.sut.lowerHand(forCall: .testEntity())
            XCTFail("Should throw and go catch")
        } catch {}
    }
}
