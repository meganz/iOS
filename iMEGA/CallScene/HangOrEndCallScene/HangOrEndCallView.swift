
import SwiftUI
import MEGASwiftUI

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
                            .foregroundColor(Color(Colors.General.Green._00C29A.name))
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: Constants.buttonsHeight)
                            .background(Color(Colors.General.Gray._363638.name))
                            .cornerRadius(Constants.cornerRadius)
                            .shadow(color: Color.black.opacity(Constants.shadowOpacity), radius: Constants.cornerRadius, x: 0, y: Constants.shadowOffsetY)
                    })
                    
                    Button(action: {
                        viewModel.dispatch(.endCallForAll)
                    }, label: {
                        Text(Strings.Localizable.Meetings.EndForAll.buttonTitle)
                            .font(.headline)
                            .foregroundColor(Color.white)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: Constants.buttonsHeight)
                            .background(Color(Colors.General.Red.ff453A.name))
                            .cornerRadius(Constants.cornerRadius)
                            .shadow(color: Color.black.opacity(Constants.shadowOpacity), radius: Constants.cornerRadius, x: 0, y: Constants.shadowOffsetY)
                    })
                }
                .padding(Constants.buttonsPadding)
            }
            .cornerRadius(Constants.cornerRadius, corners: [.topLeft, .topRight])
            .background(Color(Colors.General.Black._1c1c1e.name).edgesIgnoringSafeArea(.bottom))
        }
    }
}
