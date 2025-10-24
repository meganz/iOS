@testable import CloudDrive
import Foundation
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGASwift
import Testing

@Suite("FloatingAddButtonViewModel Tests")
@MainActor
struct FloatingAddButtonViewModelTests {

    @MainActor
    @Suite("Test for addButtonTapAction()")
    struct AddButtonTapAction {
        @Test("addButtonTapAction should toggle showActions to true")
        func addButtonTapAction() {
            let sut = makeSut()
            #expect(sut.showActions == false)
            sut.addButtonTapAction()
            #expect(sut.showActions == true)
        }
    }

    @MainActor
    @Suite("Test for showsFloatingAddButton", .serialized)
    struct ShowsFloatingAddButton {
        @Test("Intial visibility value")
        func initialValue() async {
            let sut = FloatingAddButtonViewModelTests.makeSut()
            #expect(sut.showsFloatingAddButton == false)
        }

        @Test("Feature is disabled, should not listen to visibility changes")
        func visiblityChangeDisabled() async {
            let visibilitySource = MockFloatingAddButtonVisibilityDataSource(visibilitySequence: [true].async.eraseToAnyAsyncSequence())
            let sut = FloatingAddButtonViewModelTests.makeSut(
                floatingButtonVisibilityDataSource: visibilitySource,
                featureEnabled: false
            )
            for await _ in visibilitySource.floatingButtonVisibility {}
            #expect(sut.showsFloatingAddButton == false)
        }

        @Test("Feature is enabled, should listen to visibility changes")
        func visiblityChangeEnabled() async {
            let visibilitySource = MockFloatingAddButtonVisibilityDataSource(visibilitySequence: [true].async.eraseToAnyAsyncSequence())
            let sut = FloatingAddButtonViewModelTests.makeSut(
                floatingButtonVisibilityDataSource: visibilitySource
            )
            for await _ in visibilitySource.floatingButtonVisibility {}
            #expect(sut.showsFloatingAddButton == true)
        }
    }

    @MainActor
    @Suite("Test for saveSelectedAction() and performSelectedActionAfterDismissal()")
    struct ActionInvocation {
        @Test
        func test() {
            var calledActionIndex = -1

            let action0 = NodeUploadAction(actionEntity: .chooseFromPhotos, image: .init(systemName: "star"), title: "title1") {
                calledActionIndex = 0
            }
            let action1 = NodeUploadAction(actionEntity: .capture, image: .init(systemName: "star"), title: "title2") {
                calledActionIndex = 1
            }
            let sut =  makeSut(
                uploadActions: [action0, action1]
            )

            #expect(sut.selectedAction == nil)
            #expect(calledActionIndex == -1)

            sut.saveSelectedAction(action0)
            #expect(sut.selectedAction?.id == action0.id)
            #expect(sut.selectedAction?.image == action0.image)
            #expect(sut.selectedAction?.title == action0.title)

            sut.performSelectedActionAfterDismissal()
            #expect(sut.selectedAction == nil)
            #expect(calledActionIndex == 0)
        }
    }


    private static func makeSut(
        floatingButtonVisibilityDataSource: MockFloatingAddButtonVisibilityDataSource = .init(),
        uploadActions: [NodeUploadAction] = [],
        featureEnabled: Bool = true
    ) -> FloatingAddButtonViewModel {
        FloatingAddButtonViewModel(
            floatingButtonVisibilityDataSource: floatingButtonVisibilityDataSource,
            uploadActions: uploadActions,
            featureFlagProvider: MockFeatureFlagProvider(list: [.cloudDriveRevamp: featureEnabled])
        )
    }
}

private struct MockFloatingAddButtonVisibilityDataSource: FloatingAddButtonVisibilityDataSourceProtocol {

    private let visibilitySequence: AnyAsyncSequence<Bool>

    var floatingButtonVisibility: AnyAsyncSequence<Bool> {
        visibilitySequence
    }

    init(
        visibilitySequence: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.visibilitySequence = visibilitySequence
    }
}
