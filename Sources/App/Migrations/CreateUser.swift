import Vapor
import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("username", .string, .required)
            .field("email", .string, .required)
            .field("balance", .int, .required, .custom("DEFAULT 0"))
            .field("hasFullVersion", .bool, .required, .custom("DEFAULT false"))
            .field("lastPlayTime", .date)
            .field("unlimitedUnits", .bool, .required, .custom("DEFAULT false"))
            .field("usedSoldiers", .int, .required, .custom("DEFAULT 0"))
            .field("usedTanks", .int, .required, .custom("DEFAULT 0"))
            .field("usedPlanes", .int, .required, .custom("DEFAULT 0"))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}