import Fluent
import Vapor

struct CreateTransaction: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("transactions")
            .id()
            .field("date", .datetime, .required)
            .field("isConfirmed", .bool, .required)
            .field("paymentLink", .string, .required)
            .field("amount", .int, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .create()
        
        // Add index to user_id field
        try await database.schema("transactions")
            .field("user_id", .uuid, .required)
            .foreignKey("user_id", references: "users", "id", onDelete: .cascade)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("transactions").delete()
    }
}