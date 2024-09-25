@testable import MEGA
import MEGADesignToken
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class CreateNewFolderAlertViewModelTests: XCTestCase {

    @MainActor
    func testWaitUntilFinished_whenCancelIsPerformed_shouldDismiss() async {
        await assertWaitUntilFinished()
    }

    @MainActor
    func testWaitUntilFinished_whenCreateFolderTappedWithDuplicateName_shouldThrowError() async {
        let router = MockCreateNewFolderAlertRouter()
        let nodeUseCase = MockNodeDataUseCase(createFolderResult: .failure(.nodeAlreadyExists))
        await assertWaitUntilFinished(router: router, nodeUseCase: nodeUseCase)
    }

    @MainActor
    func testWaitUntilFinished_whenCreateFolderTappedWithGenericError_shouldThrowError() async {
        let nodeUseCase = MockNodeDataUseCase(createFolderResult: .failure(.nodeCreationFailed))
        await assertWaitUntilFinished(nodeUseCase: nodeUseCase)
    }

    @MainActor
    func testWaitUntilFinished_whenCreateFolderTappedWithValidName_shouldReturnSuccess() async {
        let nodeEntity = NodeEntity()
        let nodeUseCase = MockNodeDataUseCase(createFolderResult: .success(nodeEntity))
        await assertWaitUntilFinished(nodeUseCase: nodeUseCase, expectedResult: nodeEntity, folderName: "NewFolder")
    }

    @MainActor
    func testWaitUntilFinished_whenCreateFolderTappedWithEmptyFolderName_shouldReturnNil() async {
        let nodeEntity = NodeEntity()
        let nodeUseCase = MockNodeDataUseCase(createFolderResult: .success(nodeEntity))
        await assertWaitUntilFinished(nodeUseCase: nodeUseCase, folderName: "")
    }

    @MainActor
    func testWaitUntilFinished_whenCreateFolderTappedWithInvalidFolderName_shouldReturnNil() async {
        let nodeEntity = NodeEntity()
        let nodeUseCase = MockNodeDataUseCase(createFolderResult: .success(nodeEntity))
        await assertWaitUntilFinished(nodeUseCase: nodeUseCase, expectedResult: nodeEntity, folderName: "NewFolder/")
    }

    @MainActor
    func testShouldReturnCompletion_whenTextIsNil_shouldReturnTrue() {
        assertShouldReturnCompletion(for: nil, expectedResult: true)
    }

    @MainActor
    func testShouldReturnCompletion_whenTextIsEmpty_shouldReturnFalse() {
        assertShouldReturnCompletion(for: "", expectedResult: false)
    }

    @MainActor
    func testShouldReturnCompletion_whenTextContainsInvalidChars_shouldReturnFalse() {
        assertShouldReturnCompletion(for: "NewFolder/", expectedResult: false)
    }

    @MainActor
    func testShouldReturnCompletion_whenTextContainsValidFolderName_shouldReturnTrue() {
        assertShouldReturnCompletion(for: "NewFolder", expectedResult: true)
    }

    @MainActor
    func testMakeAlertProperties_forEmptyText_shouldMatchTheExpectation() {
        assertMakeAlertProperties(
            withText: "",
            expectedResult: .init(
                title: Strings.Localizable.newFolder,
                textFieldTextColor: TokenColors.Text.primary,
                isActionEnabled: false
            )
        )
    }
    
    @MainActor
    func testMakeAlertProperties_whenTextContainsInvalidChars_shouldMatchTheExpectation() {
        assertMakeAlertProperties(
            withText: "NewFolder/",
            expectedResult: .init(
                title: Strings.Localizable.General.Error.charactersNotAllowed(
                    String.Constants.invalidFileFolderNameCharactersToDisplay
                ),
                textFieldTextColor: TokenColors.Text.error,
                isActionEnabled: false
            )
        )
    }

    @MainActor
    func testMakeAlertProperties_whenTextIsValid_shouldMatchTheExpectation() {
        assertMakeAlertProperties(
            withText: "NewFolder",
            expectedResult: .init(
                title: Strings.Localizable.newFolder,
                textFieldTextColor: TokenColors.Text.primary,
                isActionEnabled: true
            )
        )
    }

    // MARK: - Private methods.

    private typealias SUT = CreateNewFolderAlertViewModel

    @MainActor private func makeSUT(
        router: some CreateNewFolderAlertRouting = MockCreateNewFolderAlertRouter(),
        parentNode: NodeEntity = .init(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase()
    ) -> SUT {
        SUT(router: router, parentNode: parentNode, nodeUseCase: nodeUseCase)
    }

    @MainActor
    private func assertWaitUntilFinished(
        router: some CreateNewFolderAlertRouting = MockCreateNewFolderAlertRouter(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        expectedResult: NodeEntity? = nil,
        folderName: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let sut = makeSUT(router: router, nodeUseCase: nodeUseCase)

        let waitUntilFinishedTask = Task {
            await sut.waitUntilFinished()
        }

        Task {
            if let folderName {
                sut.createButtonTapped(withFolderName: folderName)
            } else {
                sut.cancelAction()
            }
        }

        let result = await waitUntilFinishedTask.value
        XCTAssertEqual(result, expectedResult, file: file, line: line)
    }

    @MainActor
    private func assertShouldReturnCompletion(
        for text: String?,
        expectedResult: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = makeSUT()
        let result = sut.shouldReturnCompletion(for: text)
        XCTAssertEqual(result, expectedResult, file: file, line: line)
    }

    @MainActor
    private func assertMakeAlertProperties(
        withText text: String,
        expectedResult: CreateNewFolderAlertViewModel.AlertProperties,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = makeSUT()
        let result = sut.makeAlertProperties(with: text)
        XCTAssertEqual(result, expectedResult, file: file, line: line)
    }
}

@MainActor
private final class MockCreateNewFolderAlertRouter: CreateNewFolderAlertRouting {
    enum Action: Equatable {
        case start
        case showNodeAlreadyExistsError
    }

    private let entity: NodeEntity?

    var actions: [Action] = []

    nonisolated init(entity: NodeEntity? = nil) {
        self.entity = entity
    }

    func start() async -> NodeEntity? {
        actions.append(.start)
        return entity
    }

    func showNodeAlreadyExistsError() {
        actions.append(.showNodeAlreadyExistsError)
    }
}
