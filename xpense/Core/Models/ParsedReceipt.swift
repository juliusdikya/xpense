import FoundationModels

@Generable
enum ParsedTransactionKind: String, Codable, CaseIterable {
    case purchase
    case income
    case transfer
    case topUp
}

/// Raw output of the receipt-parsing pipeline. Never trusted directly —
/// `ReceiptValidationService` deterministically re-checks every field
/// before anything is saved.
@Generable
struct ParsedReceipt {
    @Guide(description: "Total amount shown on the receipt, as a plain number without currency symbols or thousands separators, e.g. 125000.")
    let amount: Double

    @Guide(description: "ISO 4217 currency code, e.g. IDR, USD. Default to IDR if not shown.")
    let currencyCode: String

    @Guide(description: "The merchant, recipient, or counterparty name shown on the receipt.")
    let merchant: String

    @Guide(description: "The transaction date exactly as written on the receipt, e.g. 12/08/2026 or 12 Agustus 2026.")
    let dateText: String

    @Guide(description: "Best-guess category name for this transaction, e.g. Makanan & Minuman, Transportasi, Gaji.")
    let suggestedCategoryName: String

    @Guide(description: "Hint about which wallet this likely belongs to, inferred from the receipt type, e.g. GoPay, BCA, Cash. Empty string if unclear.")
    let suggestedWalletHint: String

    @Guide(description: "The kind of transaction this receipt represents.")
    let kind: ParsedTransactionKind

    @Guide(description: "Any additional note worth keeping, such as a transaction reference number. Empty string if none.")
    let note: String
}
