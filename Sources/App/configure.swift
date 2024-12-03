import Vapor
import Fluent
import FluentMongoDriver
import DotEnv
import JWT


public func configure(_ app: Application) async throws {
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    let path = "./.env"
    let env = try DotEnv.read(path: path)
    env.lines 
    env.load()

    var logger = Logger(label: "vapor-logger")
    logger.logLevel = .trace

    let logLevel = Environment.get("LOG_LEVEL")
    
    if let logLevel, let logLevel = Logger.Level(rawValue: logLevel) {
        logger.logLevel = logLevel
    }
    
    guard let mongoUrl = ProcessInfo.processInfo.environment["MONGODB_URL"] else {
        throw Abort(.internalServerError, reason: "MONGODB_URL not set")
    }

    print (mongoUrl)
    
     try app.databases.use(.mongo(connectionString: mongoUrl), as: .mongo)

    
    
     app.migrations.add(CreateUser())
    try await app.autoMigrate()

    // let path = "./.env"
    // let env = try DotEnv.read(path: path)
    // env.lines 
    // env.load()
    // print(ProcessInfo.processInfo.environment["CLERK_PK"]) 

    // var logger = Logger(label: "key")
    // logger.logLevel = .trace

    // let logLevel = Environment.get("LOG_LEVEL")
    
    // if let logLevel, let logLevel = Logger.Level(rawValue: logLevel) {
    //     logger.logLevel = logLevel
    // }

    let clerkPK: String = """
    -----BEGIN PUBLIC KEY-----
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsAjc1Pt7Itp7BrEUzd2B
    sdo8Yv0/OTzI/4ZNsRfW1n5qaLBJg/ZsPmwlSRGOx2cN1Lk+5U8lHZYDSuoqSHGz
    kslvYAoMKtLEaI1PZqyQjFgVlvpa6m5PN52a6Cu5fnzliqm6LVVnn3H3ATFinCgh
    +loOH8yzB7gxn9DNFljLllnEqrrgvQD5g3c5yUHF5Pn6ZASBifNsc0RdBhrRMQ2j
    zbUxbNUggUBM9kJom2uFIlJQaPLjTg0yt8NCPkbiI0UquOowBN9N0QXBD34dIKTJ
    niFaRm9TWvyHVr+Q+nDL3ipas6xEjsTr+QxOj0FMTr2VfddB0FWTkaB1uTbyCiCo
    6wIDAQAB
    -----END PUBLIC KEY-----
    """ 

    // Initialize an RSA key with public pem.
    let key = try Insecure.RSA.PublicKey(pem: clerkPK)

    await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)

    //regitser controllers
    //try app.register(collection: UserController())
    // await app.jwt.keys.add(rsa: , digestAlgorithm: .sha256)

    //app.middleware.use(MyMiddleware())

    // register routes
    try routes(app)
}
