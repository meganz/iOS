import SwiftUI

struct BackupListView: View {
    @ObservedObject var viewModel: BackupListViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.backupModels) { backupViewModel in
                DeviceCenterItemView(viewModel: backupViewModel)
            }
        }
        .listStyle(.plain)
    }
}
