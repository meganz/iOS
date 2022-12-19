import SwiftUI

struct MeetingDescriptionView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let description: String

    var body: some View {
        VStack (alignment: .leading) {
            Divider()
            Text(description)
                .font(.body)
                .padding()
            Divider()
        }
        .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
    }
}
