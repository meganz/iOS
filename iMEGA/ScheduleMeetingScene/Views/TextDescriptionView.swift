import MEGADesignToken
import MEGAL10n
import SwiftUI

struct TextDescriptionView: View {
    @Binding var descriptionText: String

    var body: some View {
        TextField(
            Strings.Localizable.Meetings.ScheduleMeeting.description,
            text: $descriptionText,
            axis: .vertical
        )
        .padding(.horizontal)
    }
}

struct FocusableTextDescriptionView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var descriptionText: String
    @FocusState var focused: Bool
    
    let onChange: (Bool) -> Void

    private enum Constants {
        static let spacing: CGFloat = 0
        static let titleHeight: CGFloat = 20
        static let titleOpacity: CGFloat = 0.6
    }
    
    var body: some View {
        Group {
            TextField(
                Strings.Localizable.Meetings.ScheduleMeeting.description,
                text: $descriptionText,
                axis: .vertical
            )
            .padding(.horizontal)
        }
        .font(.footnote)
        .lineSpacing(-2)
        .focused($focused)
        .onChange(of: focused) { isFocused in
            onChange(isFocused)
        }
        .foregroundStyle(focused ? TokenColors.Text.primary.swiftUI : TokenColors.Text.secondary.swiftUI)
        .padding(.top, !focused && $descriptionText.wrappedValue.isNotEmpty ? Constants.titleHeight : 0)
        .overlay(
            VStack(spacing: Constants.spacing) {
                if !focused && $descriptionText.wrappedValue.isNotEmpty {
                    Text(Strings.Localizable.Meetings.Info.descriptionLabel)
                        .frame(maxWidth: .infinity, maxHeight: Constants.titleHeight, alignment: .leading)
                        .padding(.horizontal)
                        .font(.body)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    Spacer()
                }
            }
        )
    }
}
