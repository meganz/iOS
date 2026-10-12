import CloudDrive
@testable import MEGA
import MEGADomain
import MEGAUIMock
import SwiftUI
import Testing
import UIKit

@MainActor
struct CreateTextFileAlertViewRouterTests {
    private static func makeRouter(isMarkdownEditorEnabled: Bool) -> CreateTextFileAlertViewRouter {
        CreateTextFileAlertViewRouter(presenter: UIViewController(), parentHandle: 5, isMarkdownEditorEnabled: isMarkdownEditorEnabled)
    }

    @Test func buildWithGateOffShowsLegacyAlert() {
        let sut = Self.makeRouter(isMarkdownEditorEnabled: false)

        #expect(sut.build() is CreateTextFileAlertViewController)
    }

    @Test func buildWithGateOnShowsNewTextFileDialog() {
        let sut = Self.makeRouter(isMarkdownEditorEnabled: true)

        #expect(sut.build() is UIHostingController<NewTextFileDialogView>)
    }

    @Test func dialogIsTheOnlyOwnerOfTheRouter() {
        weak var weakRouter: CreateTextFileAlertViewRouter?
        var dialog: UIViewController?
        do {
            let router = Self.makeRouter(isMarkdownEditorEnabled: true)
            weakRouter = router
            dialog = router.build()
        }

        #expect(dialog != nil && weakRouter != nil)
        dialog = nil
        #expect(weakRouter == nil)
    }

    // MARK: - Callers pass the gate on

    private final class PresentingNavigationController: UINavigationController {
        private(set) var presentedScreen: UIViewController?

        override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
            presentedScreen = viewControllerToPresent
        }
    }

    @Test(arguments: [true, false])
    func nodeInsertionRouterPassesTheGateToTheCreateDialog(isEnabled: Bool) {
        let navigationController = PresentingNavigationController()
        let sut = CloudDriveNodeInsertionRouter(
            navigationController: navigationController,
            isMarkdownEditorEnabled: { isEnabled },
            openNodeHandler: { _ in }
        )

        sut.createTextFileAlert(for: NodeEntity(handle: 1))

        #expect(Self.isSwiftUIDialog(navigationController.presentedScreen) == isEnabled)
        #expect(navigationController.presentedScreen is CreateTextFileAlertViewController == !isEnabled)
    }

    @Test(arguments: [true, false])
    func fileUploadingRouterPassesTheGateToTheCreateDialog(isEnabled: Bool) {
        let navigationController = PresentingNavigationController()
        let sut = FileUploadingRouter(
            navigationController: navigationController,
            baseViewController: UIViewController(),
            photoPicker: MockMEGAPhotoPicker(),
            isMarkdownEditorEnabled: { isEnabled }
        )

        sut.upload(from: .textFile)

        #expect(Self.isSwiftUIDialog(navigationController.presentedScreen) == isEnabled)
        #expect(navigationController.presentedScreen is CreateTextFileAlertViewController == !isEnabled)
    }

    private static func isSwiftUIDialog(_ viewController: UIViewController?) -> Bool {
        viewController is UIHostingController<NewTextFileDialogView>
    }

    // MARK: - Create opens the editor

    @Test(arguments: [
        (fileName: "notes.md", isEnabled: true, opensMarkdownScreen: true),
        (fileName: "notes.txt", isEnabled: true, opensMarkdownScreen: false),
        (fileName: "notes.md", isEnabled: false, opensMarkdownScreen: false)
    ])
    func createOpensTheEditorForTheNameAndTheGate(fileName: String, isEnabled: Bool, opensMarkdownScreen: Bool) {
        let presenter = PresentingNavigationController()
        let sut = CreateTextFileAlertViewRouter(presenter: presenter, parentHandle: 5, isMarkdownEditorEnabled: isEnabled)

        sut.createTextFile(fileName)

        let screen = (presenter.presentedScreen as? UINavigationController)?.viewControllers.first
        #expect((screen is MarkdownTextEditorViewController) == opensMarkdownScreen)
        #expect((screen is TextEditorViewController) == !opensMarkdownScreen)
    }
}
