import ArgumentParser
import Foundation

@main
struct App: AsyncParsableCommand {
    @Argument(help: "Authorization token for the Transifex. Example: 'Bearer 1/0ab1234567a91c2f341d5c678e9012c3b4567ed8'")
    var authorization: String

    func run() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for languageInfo in LanguageInfo.all {
                group.addTask {
                    let manager = Manager(languageInfo: languageInfo)
                    let latestDescription = try await manager.fetch(with: authorization)
                    try manager.save(latestDescription: latestDescription)
                }
            }

            return try await group.waitForAll()
        }
    }
}
