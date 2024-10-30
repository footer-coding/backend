import Vapor
import Fluent

struct CreateUser: AsyncMigration{
    func prepare(on database: Database) async throws {
        try await database.schema("user")
        .id()
        .field("username", .string, .required)
        .field("title", .string, .required)
        .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user")
        .delete()
    }
}