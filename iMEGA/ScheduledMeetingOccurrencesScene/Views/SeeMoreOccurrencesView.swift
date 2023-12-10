import MEGAL10n
import SwiftUI

struct SeeMoreOccurrencesView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let action: (() -> Void)

    private enum Constants {
        static let spacing: CGFloat = 0
        static let viewHeight: CGFloat = 44
        static let rotationRight: CGFloat = 90
        static let discolureIndicator: String = "chevron.right"
    }
    
    var body: some View {
        VStack(spacing: Constants.spacing) {
            Divider()
                .background(colorScheme == .dark ? MEGAAppColor.Gray._545458.color : MEGAAppColor.Gray._3C3C43.color)
            HStack {
                Image(systemName: Constants.discolureIndicator)
                    .foregroundColor(colorScheme == .dark ? MEGAAppColor.Gray._D1D1D1.color : MEGAAppColor.Gray._515151.color)
                    .rotationEffect(.degrees(Constants.rotationRight))
                    .padding(.horizontal)
                Text(Strings.Localizable.Meetings.Scheduled.Recurring.Occurrences.List.seeMoreOccurrences)
                    .font(.body)
                Spacer()
            }
            .frame(height: Constants.viewHeight)
            Divider()
                .background(colorScheme == .dark ? MEGAAppColor.Gray._545458.color : MEGAAppColor.Gray._3C3C43.color)
        }
        .contentShape(Rectangle())
        .listRowInsets(EdgeInsets())
        .onTapGesture {
            action()
        }
    }
}
