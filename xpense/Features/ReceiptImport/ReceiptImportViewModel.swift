import Foundation
import UIKit

enum ReceiptImportStep: Equatable {
    case pickingPhoto
    case processing
    case reviewing
    case failed(String)
}

/// Orchestrates OCR -> parsing -> deterministic validation -> editable
/// review, mirroring `TransactionFormViewModel`'s save logic so a reviewed
/// receipt saves exactly like a manually entered transaction.
@Observable
@MainActor
final class ReceiptImportViewModel {
    var step: ReceiptImportStep = .pickingPhoto

    var type: TransactionType = .expense
    var amountText: String = ""
    var feeText: String = "0"
    var date: Date = .now
    var merchant: String = ""
    var note: String = ""
    var walletID: UUID?
    var destinationWalletID: UUID?
    var categoryID: UUID?

    private(set) var ocrRawText: String = ""
    private(set) var validationErrors: [String] = []
    private(set) var duplicateWarning: String?

    let wallets: [Wallet]
    let categories: [Category]

    private let ocrService: ReceiptOCRService
    private let parsingService: ReceiptParsingService
    private let validationService: ReceiptValidationService
    private let transactionRepository: TransactionRepository

    init(
        wallets: [Wallet],
        categories: [Category],
        ocrService: ReceiptOCRService,
        parsingService: ReceiptParsingService,
        validationService: ReceiptValidationService,
        transactionRepository: TransactionRepository
    ) {
        self.wallets = wallets
        self.categories = categories
        self.ocrService = ocrService
        self.parsingService = parsingService
        self.validationService = validationService
        self.transactionRepository = transactionRepository
        self.walletID = wallets.first?.id
    }

    var categoriesForSelectedType: [Category] {
        guard type != .transfer else { return [] }
        let kind: CategoryKind = type == .income ? .income : .expense
        return categories.filter { $0.kind == kind }
    }

    func process(imageData: Data) async {
        step = .processing
        guard let uiImage = UIImage(data: imageData), let cgImage = uiImage.cgImage else {
            step = .failed("Could not read the selected image.")
            return
        }
        do {
            let text = try await ocrService.extractText(from: cgImage)
            ocrRawText = text
            let parsed = try await parsingService.parse(ocrText: text)
            let existing = try transactionRepository.fetchAll(filter: .none)
            let validation = validationService.validate(parsed, existingTransactions: existing, now: .now)
            apply(parsed, validation: validation)
            step = .reviewing
        } catch {
            step = .failed(error.localizedDescription)
        }
    }

    private func apply(_ parsed: ParsedReceipt, validation: ReceiptValidationResult) {
        type = mapKind(parsed.kind)
        amountText = validation.amountMinorUnits.map(String.init) ?? ""
        date = validation.date ?? .now
        merchant = parsed.merchant
        note = parsed.note
        categoryID = categories.first { $0.name.caseInsensitiveCompare(parsed.suggestedCategoryName) == .orderedSame }?.id
        if !parsed.suggestedWalletHint.isEmpty {
            walletID = wallets.first { $0.name.localizedCaseInsensitiveContains(parsed.suggestedWalletHint) }?.id ?? walletID
        }
        validationErrors = validation.errors
        duplicateWarning = validation.possibleDuplicate != nil
            ? "This might be a duplicate of an existing transaction."
            : nil
    }

    private func mapKind(_ kind: ParsedTransactionKind) -> TransactionType {
        switch kind {
        case .purchase: return .expense
        case .income, .topUp: return .income
        case .transfer: return .transfer
        }
    }

    @discardableResult
    func save() -> Bool {
        guard let amount = CurrencyFormatting.parseMinorUnits(from: amountText), amount > 0 else {
            step = .failed("Enter an amount greater than zero.")
            return false
        }
        guard let walletID, let wallet = wallets.first(where: { $0.id == walletID }) else {
            step = .failed("Select a wallet.")
            return false
        }

        var destinationWallet: Wallet?
        var fee: Int64 = 0
        if type == .transfer {
            guard let destinationWalletID, let destination = wallets.first(where: { $0.id == destinationWalletID }) else {
                step = .failed("Select a destination wallet.")
                return false
            }
            destinationWallet = destination
            fee = CurrencyFormatting.parseMinorUnits(from: feeText) ?? 0
        }

        var category: Category?
        if type != .transfer {
            category = categories.first { $0.id == categoryID }
        }

        let composedNote = [merchant, note].filter { !$0.isEmpty }.joined(separator: " · ")
        let transaction = Transaction(
            type: type,
            amountMinorUnits: amount,
            feeMinorUnits: fee,
            date: date,
            note: composedNote,
            needsReview: !validationErrors.isEmpty || duplicateWarning != nil,
            sourceWallet: wallet,
            destinationWallet: destinationWallet,
            category: category
        )

        do {
            try transactionRepository.create(transaction)
            return true
        } catch {
            step = .failed(error.localizedDescription)
            return false
        }
    }

    func reset() {
        step = .pickingPhoto
        amountText = ""
        feeText = "0"
        merchant = ""
        note = ""
        date = .now
        categoryID = nil
        destinationWalletID = nil
        ocrRawText = ""
        validationErrors = []
        duplicateWarning = nil
    }
}
