@testable import MEGA
@testable import MEGASDKRepoMock
import XCTest

class MyAccountHallViewControllerTests: XCTestCase {
    var myAccountVC: MyAccountHallViewController!
    var backupRootVC: CloudDriveViewController!
    var backupVC: CloudDriveViewController!
    var cloudDriveRootVC: CloudDriveViewController!
    var cameraUploadsVC: UIViewController!
    
    override func setUp() {
        super.setUp()
        myAccountVC = MyAccountHallViewController()
        backupRootVC = CloudDriveViewController()
        backupVC = CloudDriveViewController()
        cloudDriveRootVC = CloudDriveViewController()
        cameraUploadsVC = UIViewController()
    }
    
    func testUpdateViewControllerStack_appendsBackupControllers_whenBackupIsTrue() {
        let (sut, viewControllersToAdd, currentStack) = makeSUT(isBackup: true)
        let expectedStack = [myAccountVC, backupRootVC, backupVC]
        
        let updatedStack = sut.updateViewControllerStack(currentStack,
            appending: viewControllersToAdd,
            isBackup: true
        )
    
        XCTAssertEqual(updatedStack, expectedStack)
    }
    
    func testUpdateViewControllerStack_appendsCloudControllers_whenBackupIsFalse() {
        let (sut, viewControllersToAdd, currentStack) = makeSUT(isBackup: false)
        let expectedStack = [cloudDriveRootVC, cameraUploadsVC]
        
        let updatedStack = sut.updateViewControllerStack(currentStack,
            appending: viewControllersToAdd,
            isBackup: false
        )
        
        XCTAssertEqual(updatedStack, expectedStack)
    }
    
    private func makeSUT(isBackup: Bool) -> (
        sut: MyAccountHallViewController,
        viewControllersToAdd: [UIViewController],
        currentStack: [UIViewController]
    ) {
        let sut = MyAccountHallViewController()
        let currentStack: [UIViewController]
        let viewControllersToAdd: [UIViewController]
        
        if isBackup {
            currentStack = [myAccountVC, UIViewController(), UIViewController()]
            viewControllersToAdd = [backupRootVC, backupVC]
        } else {
            currentStack = [cloudDriveRootVC]
            viewControllersToAdd = [cameraUploadsVC]
        }
        
        return (sut, viewControllersToAdd, currentStack)
    }
}
