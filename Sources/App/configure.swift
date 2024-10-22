import Vapor
import Fluent
import FluentMongoDriver


// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // register routes

    // try app.databases.use(.mongo(connectionString: "<connection string>"), as: .mongo)

    try routes(app)
}
