import Foundation

protocol CategorySeeding {
    /// Inserts the default category set only if none exist yet (first launch).
    func seedDefaultsIfNeeded() throws
}

@MainActor
struct DefaultCategorySeeder: CategorySeeding {
    static let defaultExpenseCategories = [
        "Makanan & Minuman", "Transportasi", "Belanja", "Tagihan", "Hiburan", "Kesehatan", "Lainnya",
    ]
    static let defaultIncomeCategories = ["Gaji", "Bonus", "Hadiah", "Lainnya"]

    private let categoryRepository: CategoryRepository

    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    func seedDefaultsIfNeeded() throws {
        let existing = try categoryRepository.fetchAll(kind: nil, includeArchived: true)
        guard existing.isEmpty else { return }

        for (index, name) in Self.defaultExpenseCategories.enumerated() {
            try categoryRepository.create(name: name, kind: .expense, iconName: "tag", sortOrder: index)
        }
        for (index, name) in Self.defaultIncomeCategories.enumerated() {
            try categoryRepository.create(name: name, kind: .income, iconName: "tag", sortOrder: index)
        }
    }
}
