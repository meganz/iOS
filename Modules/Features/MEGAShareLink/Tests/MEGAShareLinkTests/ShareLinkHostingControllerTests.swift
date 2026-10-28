import MEGAShareLink
import SwiftUI
import Testing

@MainActor
@Suite("ShareLinkHostingController")
struct ShareLinkHostingControllerTests {
    @Test("presents as a form sheet")
    func init_presentsAsFormSheet() {
        #expect(makeSUT().modalPresentationStyle == .formSheet)
    }

    @Test("is its own presentation delegate")
    func init_isOwnPresentationDelegate() throws {
        let sut = makeSUT()

        let delegate = try #require(sut.presentationController?.delegate)

        #expect(delegate === sut)
    }

    @Test(
        "stays a form sheet only while both size classes are regular, otherwise adapts to full screen",
        arguments: [
            (SizeClasses(horizontal: .compact, vertical: .regular), UIModalPresentationStyle.fullScreen),
            (SizeClasses(horizontal: .compact, vertical: .compact), .fullScreen),
            (SizeClasses(horizontal: .regular, vertical: .compact), .fullScreen),
            (SizeClasses(horizontal: .regular, vertical: .regular), .none),
            (SizeClasses(horizontal: .unspecified, vertical: .regular), .fullScreen),
            (SizeClasses(horizontal: .regular, vertical: .unspecified), .fullScreen)
        ]
    )
    private func adaptivePresentationStyle_followsSizeClasses(
        sizeClasses: SizeClasses,
        expectedStyle: UIModalPresentationStyle
    ) throws {
        let sut = makeSUT()
        let presentationController = try #require(sut.presentationController)
        let delegate = try #require(presentationController.delegate)
        let traits = UITraitCollection {
            $0.horizontalSizeClass = sizeClasses.horizontal
            $0.verticalSizeClass = sizeClasses.vertical
        }

        let adaptedStyle = delegate.adaptivePresentationStyle?(for: presentationController, traitCollection: traits)

        #expect(adaptedStyle == expectedStyle)
    }

    private func makeSUT() -> ShareLinkHostingController<EmptyView> {
        ShareLinkHostingController(rootView: EmptyView())
    }
}

private struct SizeClasses: CustomTestStringConvertible {
    let horizontal: UIUserInterfaceSizeClass
    let vertical: UIUserInterfaceSizeClass

    var testDescription: String {
        "horizontal \(Self.name(of: horizontal)), vertical \(Self.name(of: vertical))"
    }

    private static func name(of sizeClass: UIUserInterfaceSizeClass) -> String {
        switch sizeClass {
        case .compact: "compact"
        case .regular: "regular"
        default: "unspecified"
        }
    }
}
