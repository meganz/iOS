import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct HangOrEndCallView: View {
    var viewModel: HangOrEndCallViewModel
    
    private enum Constants {
        static let cornerRadius: CGFloat = 8
        static let shadowOffsetY: CGFloat = 1
        static let shadowOpacity: CGFloat = 0.15
        static let buttonsSpacing: CGFloat = 16
        static let buttonsHeight: CGFloat = 50
        static let buttonsPadding: CGFloat = 36
    }
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                VStack(spacing: Constants.buttonsSpacing) {
                    Button(action: {
                        viewModel.dispatch(.leaveCall)
                    }, label: {
                        Text(Strings.Localizable.Meetings.LeaveCall.buttonTitle)
                            .font(.headline)
                            .foregroundColor(MEGAAppColor.Green._00C29A.color)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: Constants.buttonsHeight)
                            .background(MEGAAppColor.Gray._363638.color)
                            .cornerRadius(Constants.cornerRadius)
                            .shadow(color: MEGAAppColor.Black._000000.color.opacity(Constants.shadowOpacity), radius: Constants.cornerRadius, x: 0, y: Constants.shadowOffsetY)
                    })
                    
                    Button(action: {
                        viewModel.dispatch(.endCallForAll)
                    }, label: {
                        Text(Strings.Localizable.Meetings.EndForAll.buttonTitle)
                            .font(.headline)
                            .foregroundColor(MEGAAppColor.White._FFFFFF.color)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: Constants.buttonsHeight)
                            .background(Color(.redFF453A))
                            .cornerRadius(Constants.cornerRadius)
                            .shadow(color: MEGAAppColor.Black._000000.color.opacity(Constants.shadowOpacity), radius: Constants.cornerRadius, x: 0, y: Constants.shadowOffsetY)
                    })
                }
                .padding(Constants.buttonsPadding)
            }
            .cornerRadius(Constants.cornerRadius, corners: [.topLeft, .topRight])
            .background(MEGAAppColor.Black._1C1C1E.color.edgesIgnoringSafeArea(.bottom))
        }
    }
}
