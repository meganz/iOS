import Foundation
import MEGAL10n

@MainActor
final class NodeTagsCellController: NSObject {
    private static let reuseIdentifier = "NodeTagsCellID"

    static func registerCell(for tableView: UITableView) {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.reuseIdentifier)
    }
}

extension NodeTagsCellController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.reuseIdentifier, for: indexPath)
        cell.textLabel?.text = Strings.Localizable.CloudDrive.NodeInfo.NodeTags.header
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension NodeTagsCellController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        NodeInfoCellHeaderView(title: Strings.Localizable.CloudDrive.NodeInfo.NodeTags.header, topPadding: 10).toUIView()
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }
}
