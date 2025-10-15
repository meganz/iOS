import Combine
@testable import MEGA
import MEGADomain
import XCTest

final class MockNodeInsertionRouter: NodeInsertionRouting {
    enum Action: Equatable {
        case createTextFileAlert(NodeEntity)
        case createNewFolder(NodeEntity)
        case scanDocument(NodeEntity)
        case importFromFiles(NodeEntity)
        case capturePhotoVideo(NodeEntity)
        case choosePhotoVideo(NodeEntity)
    }

    @Published var actions: [Action] = []

    func shouldMatch(expectedAction: Action, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actions.first, expectedAction, file: file, line: line)
    }

    func createTextFileAlert(for nodeEntity: NodeEntity) {
        actions.append(.createTextFileAlert(nodeEntity))
    }

    func createNewFolder(for nodeEntity: NodeEntity) {
        actions.append(.createNewFolder(nodeEntity))
    }

    func scanDocument(for nodeEntity: NodeEntity) {
        actions.append(.scanDocument(nodeEntity))
    }

    func importFromFiles(for nodeEntity: NodeEntity) {
        actions.append(.importFromFiles(nodeEntity))
    }

    func capturePhotoVideo(for nodeEntity: NodeEntity) {
        actions.append(.capturePhotoVideo(nodeEntity))
    }

    func choosePhotoVideo(for nodeEntity: NodeEntity) {
        actions.append(.choosePhotoVideo(nodeEntity))
    }
}
