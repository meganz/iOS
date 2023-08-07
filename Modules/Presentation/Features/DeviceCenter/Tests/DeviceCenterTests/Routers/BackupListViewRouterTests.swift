@testable import DeviceCenter
import MEGATest
import SwiftUI
import XCTest

final class BAckupListsViewRouterTests: XCTestCase {
    
    func testBuild_rendersCorrectViewController() throws {
        let (sut, _) = try makeSUT()
        
        let resultViewController = sut.build()
        
        XCTAssert(resultViewController is UIHostingController<BackupListView>)
    }
    
    func testStart_pushCorrectViewController() throws {
        let (sut, mockPresenter) = try makeSUT()
        
        sut.start()
        
        let viewController = try XCTUnwrap(mockPresenter.viewControllers.first)
        
        XCTAssertTrue(viewController is UIHostingController<BackupListView>)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> (sut: BackupListViewRouter, mockPresenter: UINavigationController) {
        
        let mockPresenter = UINavigationController()
        
        let sut = BackupListViewRouter(
            deviceName: "Device 1",
            backups: [],
            navigationController: mockPresenter,
            backupListAssets:
                BackupListAssets(
                    backupTypes: [
                        BackupType(type: .backupUpload, iconName: "backup")
                    ]
                ),
            backupStatuses: [
                BackupStatus(status: .upToDate, title: "", colorName: "blue", iconName: "circle.fill")
            ]
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, mockPresenter)
    }
}
