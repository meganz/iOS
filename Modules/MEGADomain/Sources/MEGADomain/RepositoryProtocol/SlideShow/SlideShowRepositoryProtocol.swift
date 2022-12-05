import Foundation

public protocol SlideShowRepositoryProtocol: RepositoryProtocol {
    func loadConfiguration() -> SlideShowConfigurationEntity
    func saveConfiguration(_ config: SlideShowConfigurationEntity)
}
