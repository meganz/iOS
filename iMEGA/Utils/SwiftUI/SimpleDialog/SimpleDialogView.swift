import MEGADesignToken
import SwiftUI

struct SimpleDialogConfig {
    let imageResource: ImageResource
    let title: String
    let message: String
    let buttonTitle: String
    let buttonAction: () -> Void
}

/// This view is intended to show a dialog to the user.
/// Can be wrapped in a UIKit view or used in SwiftUI directly.
/// It contains  image, title, description and  button for an action.
struct SimpleDialogView: View {
    @Environment(\.colorScheme) private var colorScheme
    let dialogConfig: SimpleDialogConfig

    init(dialogConfig: SimpleDialogConfig) {
        self.dialogConfig = dialogConfig
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(dialogConfig.imageResource)
                .resizable()
                .frame(width: 90, height: 90)
            Text(dialogConfig.title)
                .font(isDesignTokenEnabled ? .callout : .headline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Text(dialogConfig.message)
                .multilineTextAlignment(.center)
                .font(isDesignTokenEnabled ? .subheadline : .footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            Button {
                dialogConfig.buttonAction()
            } label: {
                Text(dialogConfig.buttonTitle)
                    .frame(maxWidth: 288)
                    .frame(height: 50)
                    .background(isDesignTokenEnabled ? TokenColors.Icon.accent.swiftUI : MEGAAppColor.Green._00A886.color)
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.inverseAccent.swiftUI : MEGAAppColor.White._FFFFFF.color)
                    .cornerRadius(10)
                    .font(.headline)
            }
        }
        .padding(30)
        .background(TokenColors.Background.page.swiftUI)
    }
}

struct SimpleDialogView_Previews: PreviewProvider {
    static var previews: some View {
        let dialogConfig = SimpleDialogConfig(
            imageResource: .upgradeToProPlan,
            title: "Dialog title",
            message: "Fancy dialog message",
            buttonTitle: "Button action title"
        ) { }
        VStack {
            SimpleDialogView(dialogConfig: dialogConfig)
                .colorScheme(.light)
            
            SimpleDialogView(dialogConfig: dialogConfig)
                .colorScheme(.dark)
        }
    }
}
