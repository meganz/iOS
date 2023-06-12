import SwiftUI

struct ScheduleMeetingCreationCustomOptionsWheelPickerView<T: Hashable>: View {
    let label: String
    let options: [T]
    @Binding var selection: T
    let convertOptionToString: (T) -> String
    
    var body: some View {
        Picker(label, selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(convertOptionToString(option))
            }
        }
        .pickerStyle(.wheel)
    }
}
