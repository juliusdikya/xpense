import Foundation
import FoundationModels

enum ReceiptParsingError: LocalizedError {
    case modelUnavailable(String)
    case parsingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .modelUnavailable(let reason):
            return "On-device AI is unavailable: \(reason)"
        case .parsingFailed(let error):
            return "Failed to parse receipt: \(error.localizedDescription)"
        }
    }
}

protocol ReceiptParsingService {
    func parse(ocrText: String) async throws -> ParsedReceipt
}

/// Text-only prompting (`session.respond(to:generating:)`), not multimodal
/// image Attachment — `Attachment` requires iOS 27, below this project's
/// iOS 26 minimum. The image is never sent to the model; only OCR'd text is.
struct FoundationModelsReceiptParsingService: ReceiptParsingService {
    func parse(ocrText: String) async throws -> ParsedReceipt {
        switch SystemLanguageModel.default.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw ReceiptParsingError.modelUnavailable("\(reason)")
        }

        let session = LanguageModelSession(instructions: """
            You extract structured transaction details from Indonesian receipts, payment \
            confirmations, and bank/e-wallet transfer proofs (QRIS, BCA, Mandiri, BRI, BNI, \
            GoPay, OVO, DANA, ShopeePay, marketplace receipts). Read the OCR text and extract \
            the fields exactly as described. If a field isn't present, make a reasonable guess \
            or leave it empty; never invent an amount.
            """)

        do {
            let response = try await session.respond(to: ocrText, generating: ParsedReceipt.self)
            return response.content
        } catch {
            throw ReceiptParsingError.parsingFailed(error)
        }
    }
}
