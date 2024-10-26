import Vapor
import Fluent
import FluentMongoDriver
import DotEnv



// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    let path = "./.env"
    var env = try DotEnv.read(path: path)
    env.lines // [Line] (key=value pairs)
    env.load()
    print(ProcessInfo.processInfo.environment["MONGODB_URL"]) 
    var logger = Logger(label: "vapor-logger")
    logger.logLevel = .trace

    // 2. Environment variable for log level
    let logLevel = Environment.get("LOG_LEVEL")
    
    // 3. Set log level if provided
    if let logLevel, let logLevel = Logger.Level(rawValue: logLevel) {
        logger.logLevel = logLevel
    }
    
    // 4. Database URL from environment variable
    guard let mongoUrl = Environment.get("MONGODB_URL") else {
        throw Abort(.internalServerError, reason: "MONGODB_URL not set")
    }
    
     try app.databases.use(.mongo(connectionString: mongoUrl), as: .mongo)

    //regitser controllers
    try app.register(collection: PersonController())

    // register routes
    try routes(app)
}
