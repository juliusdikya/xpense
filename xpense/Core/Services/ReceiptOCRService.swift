import CoreGraphics
import Foundation
import Vision

enum ReceiptOCRError: LocalizedError {
    case emptyText

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "No readable text was found in the image."
        }
    }
}

protocol ReceiptOCRService {
    func extractText(from image: CGImage) async throws -> String
}

/// Uses Vision's `RecognizeTextRequest` (iOS 18+), not the older
/// `VNRecognizeTextRequest`/`VNImageRequestHandler` class API.
struct VisionReceiptOCRService: ReceiptOCRService {
    func extractText(from image: CGImage) async throws -> String {
        var request = RecognizeTextRequest()
        request.recognitionLanguages = [Locale.Language(identifier: "id"), Locale.Language(identifier: "en")]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let observations = try await request.perform(on: image)
        let lines = observations.map(\.transcript).filter { !$0.isEmpty }
        guard !lines.isEmpty else { throw ReceiptOCRError.emptyText }
        return lines.joined(separator: "\n")
    }
}
