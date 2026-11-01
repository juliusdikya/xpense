import Foundation

/// In-memory mock for previews and tests. No SwiftData involved.
final class MockCategoryRepository: CategoryRepository {
    private(set) var categories: [Category]

    init(categories: [Category] = MockCategoryRepository.sampleCategories) {
        self.categories = categories
    }

    func fetchAll(kind: CategoryKind?, includeArchived: Bool) throws -> [Category] {
        let base = includeArchived ? categories : categories.filter { !$0.isArchived }
        guard let kind else { return base }
        return base.filter { $0.kind == kind }
    }

    func fetch(id: UUID) throws -> Category? {
        categories.first { $0.id == id }
    }

    @discardableResult
    func create(name: String, kind: CategoryKind, iconName: String, sortOrder: Int) throws -> Category {
        let category = Category(name: name, kind: kind, iconName: iconName, sortOrder: sortOrder)
        categories.append(category)
        return category
    }

    func update(_ category: Category) throws {}

    func archive(_ category: Category) throws {
        category.isArchived = true
    }

    static var sampleCategories: [Category] {
        [
            Category(name: "Makanan & Minuman", kind: .expense, sortOrder: 0),
            Category(name: "Transportasi", kind: .expense, sortOrder: 1),
            Category(name: "Gaji", kind: .income, sortOrder: 0),
        ]
    }
}
