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

    
    let logLevel = Environment.get("LOG_LEVEL")
    
    
    if let logLevel, let logLevel = Logger.Level(rawValue: logLevel) {
        logger.logLevel = logLevel
    }
    
    
    guard let mongoUrl = Environment.get("MONGODB_URL") else {
        throw Abort(.internalServerError, reason: "MONGODB_URL not set")
    }
    
     try app.databases.use(.mongo(connectionString: mongoUrl), as: .mongo)

    //regitser controllers
    try app.register(collection: PersonController())

    // register routes
    try routes(app)
}
