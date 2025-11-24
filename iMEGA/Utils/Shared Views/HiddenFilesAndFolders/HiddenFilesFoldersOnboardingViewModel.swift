import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAL10n
import SwiftUI

@MainActor
struct HiddenFilesFoldersOnboardingViewModel {
    struct DescriptionItemViewModel: Identifiable {
        struct HighlightedText {
            let text: String
            let action: (() -> Void)?
        }
        let id = UUID()
        let icon: Image
        let title: String
        let description: String
        let descriptionHighlightedText: HighlightedText?
        
        init(icon: Image, title: String, description: String, descriptionHighlightedText: HighlightedText? = nil) {
            self.icon = icon
            self.title = title
            self.description = description
            self.descriptionHighlightedText = descriptionHighlightedText
        }
    }
    let showPrimaryButtonOnly: Bool
    let showNavigationBar: Bool
    
    var descriptionItems: [DescriptionItemViewModel] {
        makeDescriptionItems()
    }
    
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let hideFilesAndFoldersRouter: any HideFilesAndFoldersRouting
    private let tracker: any AnalyticsTracking
    private let screenEvent: (any ScreenViewEventIdentifier)?
    private let dismissEvent: (any ButtonPressedEventIdentifier)?
    
    init(
        showPrimaryButtonOnly: Bool,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        hideFilesAndFoldersRouter: some HideFilesAndFoldersRouting,
        showNavigationBar: Bool = true,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        screenEvent: (any ScreenViewEventIdentifier)? = nil,
        dismissEvent: (any ButtonPressedEventIdentifier)? = nil
    ) {
        self.showPrimaryButtonOnly = showPrimaryButtonOnly
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.hideFilesAndFoldersRouter = hideFilesAndFoldersRouter
        self.showNavigationBar = showNavigationBar
        self.tracker = tracker
        self.screenEvent = screenEvent
        self.dismissEvent = dismissEvent
    }
    
    func onViewAppear() {
        guard let screenEvent else { return }
        tracker.trackAnalyticsEvent(with: screenEvent)
    }
    
    func onDismissButtonTapped() {
        guard let dismissEvent else { return }
        tracker.trackAnalyticsEvent(with: dismissEvent)
    }
    
    private func makeDescriptionItems() -> [DescriptionItemViewModel] {
        [
            .init(icon: MEGAAssets.Image.eyeOffRegular,
                  title: Strings.Localizable.Onboarding.HiddenFilesAndFolders.Content.Item.One.title,
                  description: Strings.Localizable.Onboarding.HiddenFilesAndFolders.Content.Item.One.message),
            makeOutOfSignDescription(),
            .init(icon: MEGAAssets.Image.eyeRegular,
                  title: Strings.Localizable.Onboarding.HiddenFilesAndFolders.Content.Item.Three.title,
                  description: Strings.Localizable.Onboarding.HiddenFilesAndFolders.Content.Item.Three.message)
        ]
    }
    
    private func makeOutOfSignDescription() -> DescriptionItemViewModel {
        let message = Strings.Localizable.Onboarding.HiddenFilesAndFolders.Content.Item.ControlVisibility.message
        let description = message
            .replacing("[A]", with: "")
            .replacing("[/A]", with: "")
        let highlightedText = message.subString(from: "[A]", to: "[/A]") ?? ""
        
        return .init(
            icon: MEGAAssets.Image.imagesRegular,
            title: Strings.Localizable.Onboarding.HiddenFilesAndFolders.Content.Item.Two.title,
            description: description,
            descriptionHighlightedText: makeOutOfSightDescriptionHighlightText(text: highlightedText))
    }
    
    private func makeOutOfSightDescriptionHighlightText(text: String) -> DescriptionItemViewModel.HighlightedText? {
        guard sensitiveNodeUseCase.isAccessible() else { return nil }
        return .init(text: text, action: hideFilesAndFoldersRouter.showUserInterfaceSettings)
    }
}
