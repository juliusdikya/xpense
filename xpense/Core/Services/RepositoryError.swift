import Foundation

enum RepositoryError: LocalizedError {
    case notFound
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "The requested record could not be found."
        case .saveFailed(let underlying):
            return "Failed to save changes: \(underlying.localizedDescription)"
        }
    }
}
