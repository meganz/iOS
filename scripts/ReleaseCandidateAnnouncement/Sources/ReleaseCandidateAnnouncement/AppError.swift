import Foundation

enum AppError: Error {
    case invalidURL(String)
    case failedToSendMessage(String)
}
