import UIKit

protocol CreateContextMenuRepositoryProtocol: RepositoryProtocol {
    func createContextMenu(config: CMConfigEntity) -> CMEntity?
}
