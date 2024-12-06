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
    }

    func revert(on database: Database) async throws {
        try await database.schema("transactions").delete()
    }
}