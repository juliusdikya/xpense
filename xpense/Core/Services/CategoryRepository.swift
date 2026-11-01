import Foundation
import SwiftData

protocol CategoryRepository {
    func fetchAll(kind: CategoryKind?, includeArchived: Bool) throws -> [Category]
    func fetch(id: UUID) throws -> Category?
    @discardableResult
    func create(name: String, kind: CategoryKind, iconName: String, sortOrder: Int) throws -> Category
    func update(_ category: Category) throws
    /// Categories in use are archived, never hard-deleted.
    func archive(_ category: Category) throws
}

@MainActor
final class SwiftDataCategoryRepository: CategoryRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll(kind: CategoryKind?, includeArchived: Bool) throws -> [Category] {
        let sort = [SortDescriptor(\Category.sortOrder)]
        let all: [Category]
        if includeArchived {
            all = try modelContext.fetch(FetchDescriptor<Category>(sortBy: sort))
        } else {
            let predicate = #Predicate<Category> { !$0.isArchived }
            all = try modelContext.fetch(FetchDescriptor<Category>(predicate: predicate, sortBy: sort))
        }
        guard let kind else { return all }
        return all.filter { $0.kind == kind }
    }

    func fetch(id: UUID) throws -> Category? {
        let predicate = #Predicate<Category> { $0.id == id }
        return try modelContext.fetch(FetchDescriptor<Category>(predicate: predicate)).first
    }

    @discardableResult
    func create(name: String, kind: CategoryKind, iconName: String, sortOrder: Int) throws -> Category {
        let category = Category(name: name, kind: kind, iconName: iconName, sortOrder: sortOrder)
        modelContext.insert(category)
        try save()
        return category
    }

    func update(_ category: Category) throws {
        try save()
    }

    func archive(_ category: Category) throws {
        category.isArchived = true
        try save()
    }

    private func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.saveFailed(underlying: error)
        }
    }
}
