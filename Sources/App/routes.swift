import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "chuj"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    app.get("hello" , ":user") {req async -> String in 
        let user = req.parameters.get("user") ?? "puste jest"
        return "hello, \(user)!"
    }

    app.get("hello", ":user", "age") {req async -> String in
        return "hello"
    }

    
    
}
