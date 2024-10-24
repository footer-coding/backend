import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "działą ?"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
}
