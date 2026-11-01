import PhotosUI
import SwiftUI

struct ReceiptImportView: View {
    @State private var viewModel: ReceiptImportViewModel
    @State private var photoItem: PhotosPickerItem?

    init(
        walletRepository: WalletRepository,
        categoryRepository: CategoryRepository,
        ocrService: ReceiptOCRService,
        parsingService: ReceiptParsingService,
        validationService: ReceiptValidationService,
        transactionRepository: TransactionRepository
    ) {
        let wallets = (try? walletRepository.fetchAll(includeArchived: false)) ?? []
        let categories = (try? categoryRepository.fetchAll(kind: nil, includeArchived: false)) ?? []
        _viewModel = State(initialValue: ReceiptImportViewModel(
            wallets: wallets,
            categories: categories,
            ocrService: ocrService,
            parsingService: parsingService,
            validationService: validationService,
            transactionRepository: transactionRepository
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.step {
                case .pickingPhoto:
                    ContentUnavailableView {
                        Label("Import a Receipt", systemImage: "camera.viewfinder")
                    } description: {
                        Text("Pick a screenshot of a receipt, payment confirmation, or transfer proof.")
                    } actions: {
                        PhotosPicker("Choose Photo", selection: $photoItem, matching: .images)
                    }
                case .processing:
                    ProgressView("Reading receipt…")
                case .reviewing:
                    reviewForm
                case .failed(let message):
                    ContentUnavailableView {
                        Label("Couldn't Read Receipt", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Try Again") {
                            photoItem = nil
                            viewModel.reset()
                        }
                    }
                }
            }
            .navigationTitle("Import Receipt")
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    guard let data = try? await newItem.loadTransferable(type: Data.self) else {
                        viewModel.step = .failed("Could not load the selected photo.")
                        return
                    }
                    await viewModel.process(imageData: data)
                }
            }
        }
    }

    @ViewBuilder
    private var reviewForm: some View {
        Form {
            if !viewModel.validationErrors.isEmpty || viewModel.duplicateWarning != nil {
                Section("Needs review") {
                    ForEach(viewModel.validationErrors, id: \.self) { error in
                        Text(error).foregroundStyle(.orange)
                    }
                    if let duplicateWarning = viewModel.duplicateWarning {
                        Text(duplicateWarning).foregroundStyle(.orange)
                    }
                }
            }

            Picker("Type", selection: $viewModel.type) {
                Text("Expense").tag(TransactionType.expense)
                Text("Income").tag(TransactionType.income)
                Text("Transfer").tag(TransactionType.transfer)
            }
            .pickerStyle(.segmented)

            TextField("Amount", text: $viewModel.amountText)
                .numericKeyboard()
            TextField("Merchant", text: $viewModel.merchant)

            Picker("Wallet", selection: $viewModel.walletID) {
                ForEach(viewModel.wallets, id: \.id) { wallet in
                    Text(wallet.name).tag(Optional(wallet.id))
                }
            }

            if viewModel.type == .transfer {
                Picker("To wallet", selection: $viewModel.destinationWalletID) {
                    Text("Select").tag(UUID?.none)
                    ForEach(viewModel.wallets, id: \.id) { wallet in
                        Text(wallet.name).tag(Optional(wallet.id))
                    }
                }
                TextField("Fee (optional)", text: $viewModel.feeText)
                    .numericKeyboard()
            } else {
                Picker("Category", selection: $viewModel.categoryID) {
                    Text("Select").tag(UUID?.none)
                    ForEach(viewModel.categoriesForSelectedType, id: \.id) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }
            }

            DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
            TextField("Note", text: $viewModel.note)

            DisclosureGroup("Raw OCR Text") {
                Text(viewModel.ocrRawText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    photoItem = nil
                    viewModel.reset()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if viewModel.save() {
                        photoItem = nil
                        viewModel.reset()
                    }
                }
            }
        }
    }
}

#Preview {
    ReceiptImportView(
        walletRepository: MockWalletRepository(),
        categoryRepository: MockCategoryRepository(),
        ocrService: VisionReceiptOCRService(),
        parsingService: FoundationModelsReceiptParsingService(),
        validationService: DefaultReceiptValidationService(),
        transactionRepository: MockTransactionRepository()
    )
}
