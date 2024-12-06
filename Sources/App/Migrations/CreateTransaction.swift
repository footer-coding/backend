
import Fluent
import Vapor

struct CreateTransaction:AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("transactions")
            .id()
            .field("username", .string, .required)
            .field("amount", .int, .required)
            .field("paymentIntentId", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("transactions").delete()
    }
}