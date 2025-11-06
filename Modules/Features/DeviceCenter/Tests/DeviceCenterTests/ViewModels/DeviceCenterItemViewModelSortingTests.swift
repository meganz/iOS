@testable import DeviceCenter
import MEGADomain
import MEGADomainMock
import XCTest

final class DeviceCenterItemViewModelSortingTests: XCTestCase {
    @MainActor
    func testSortedByName_ascending_correctOrder() {
        validateSortingOrder(
            for: .ascending,
            expectedOrder: ["backup1", "backup2", "backup3"]
        )
    }

    @MainActor
    func testSortedByName_descending_correctOrder() {
        validateSortingOrder(
            for: .descending,
            expectedOrder: ["backup3", "backup2", "backup1"]
        )
    }

    @MainActor
    func testSortedByNodeSize_largestFirst_correctOrder() {
        validateSortingOrder(
            for: .largest,
            expectedOrder: ["backup3", "backup2", "backup1"]
        )
    }

    @MainActor
    func testSortedByNodeSize_smallestFirst_correctOrder() {
        validateSortingOrder(
            for: .smallest,
            expectedOrder: ["backup1", "backup2", "backup3"]
        )
    }

    @MainActor
    func testSortedByCreationTime_newestFirst_correctOrder() {
        validateSortingOrder(
            for: .newest,
            expectedOrder: ["backup1", "backup2", "backup3"]
        )
    }

    @MainActor
    func testSortedByCreationTime_oldestFirst_correctOrder() {
        validateSortingOrder(
            for: .oldest,
            expectedOrder: ["backup3", "backup2", "backup1"]
        )
    }

    @MainActor
    func testSortedByLabel_correctOrder() {
        validateSortingOrder(
            for: .label,
            expectedOrder: ["backup1", "backup2", "backup3"]
        )
    }

    @MainActor
    func testSortedByFavourite_correctOrder() {
        validateSortingOrder(
            for: .favourite,
            expectedOrder: ["backup3", "backup1", "backup2"]
        )
    }

    @MainActor
    private func validateSortingOrder(
        for sortingCriteria: SortType,
        expectedOrder: [String]
    ) {
        let sut = makeSUT()
        let sortedNames = sut.sorted(
            by: sortingCriteria
        ).map(\.name)
        
        XCTAssertEqual(sortedNames, expectedOrder)
    }

    @MainActor
    private func makeSUT() -> [DeviceCenterItemViewModel] {
        let mockCurrentDeviceId = "1"
        let oneDayInSeconds = 86400.0
        let oneWeekInSeconds = 604800.0
        let oneMonthInSeconds = 2629800.0

        let backups = [
            BackupEntity(
                id: 1,
                name: "backup1",
                deviceId: mockCurrentDeviceId, 
                rootHandle: 1,
                type: .twoWay,
                status: .upToDate
            ),
            BackupEntity(
                id: 2,
                name: "backup2",
                deviceId: mockCurrentDeviceId,
                rootHandle: 2,
                type: .upSync,
                status: .upToDate
            ),
            BackupEntity(
                id: 3,
                name: "backup3",
                deviceId: mockCurrentDeviceId,
                rootHandle: 3,
                type: .cameraUpload,
                status: .upToDate
            )
        ]

        let nodes = [
            NodeEntity(
                name: "Node1",
                handle: 1, label: .blue, 
                size: 10, 
                creationTime: 
                    Date().addingTimeInterval(
                        -oneDayInSeconds
                    )
            ),
            NodeEntity(
                name: "Node2",
                handle: 2, label: .blue,
                size: 20, 
                creationTime: 
                    Date().addingTimeInterval(
                        -oneWeekInSeconds
                    )
            ),
            NodeEntity(
                name: "Node3",
                handle: 3, 
                isFavourite: true,
                size: 30, 
                creationTime: 
                    Date().addingTimeInterval(
                        -oneMonthInSeconds
                    )
            )
        ]

        let device = DeviceEntity(
            id: mockCurrentDeviceId,
            name: "device1",
            backups: backups,
            status: .upToDate
        )
        let nodeUseCase = MockNodeDataUseCase(
            nodes: nodes
        )
        let deviceCenterUseCase = MockDeviceCenterUseCase(
            devices: [device],
            currentDeviceId: mockCurrentDeviceId
        )
        let assets = ItemAssets(
            statusAssets: StatusAssets(
                title: "",
                color: .blue,
                iconName: ""
            )
        )

        return backups.map { backup in
            DeviceCenterItemViewModel(
                deviceCenterUseCase: deviceCenterUseCase,
                nodeUseCase: nodeUseCase,
                deviceCenterBridge: DeviceCenterBridge(),
                itemType: .backup(backup),
                sortedAvailableActions: [:],
                isCUActionAvailable: false,
                assets: assets,
                currentDeviceUUID: { "" }
            )
        }
    }
}
