import Vapor
import Fluent
import FluentMongoDriver
//class name(PersonController) and RouteCollection protocol
class PersonController: RouteCollection {
    //function, boot method set up app routes, RoutesBuilder allow me to define and configure routes, throws basically means that 
    //the program can throw an error
    func boot(routes: RoutesBuilder) throws {
        //routes from RoutesBuilder just like above
        //grouped is a method from routes object, it creates a route group
        let api = routes.grouped("api")
        //post for creating, use calls a create func from the bottom
        api.post("person", use: create)
        //get for pulling data, finding
        api.get("person", use: getAll)
        //:personId for finding person with this id
        api.get("person", ":personId", use: getById)
        //this delete an person data
        api.delete("person", ":personId", use: deletePerson)
        //put for update
        api.put("person", ":personId", use: updatePerson)
    }   
    //function for updating
    func updatePerson(req: Request) async throws -> Person {
        //retriving personId from req parameters, guard means that to continue code this conditional must be true
        guard let personId = req.parameters.get("personId", as: UUID.self) else {
            throw Abort(.notFound) //throw an error if personId is not found
        }
        //this is finding a Person object in the database 
        guard let person = try await Person.find(personId, on: req.db) else {
            throw Abort(.notFound, reason: "PersonId \(personId) was not found")
        }
        //This line decodes the request body into a Person object. 
        //It expects the incoming data to be in a format that matches the Person model (usually JSON)
        let updatePerson = try req.content.decode(Person.self)
        //properties from person updated to properties from the updatePerson
        person.name = updatePerson.name
        person.lname = updatePerson.lname
        person.age = updatePerson.age
        person.city = updatePerson.city

        //The try await keywords indicate that this operation is asynchronous and can throw an error.
        //This line saves the updated person object back to the database.
        try await person.update(on: req.db)
        return person
    }
    //func for deleting person data
    func deletePerson(req: Request) async throws -> Person {
        //same
        guard let personId = req.parameters.get("personId", as: UUID.self) else {
            throw Abort(.notFound)
        }
        //same
        guard let person = try await Person.find(personId, on: req.db) else {
            throw Abort(.notFound, reason: "PersonId \(personId) was not found")
        }
        //this delet person obj from db and can throw an error
        try await person.delete(on: req.db)
        return person
    }  
    //func for finding person obj by id
    func getById(req: Request) async throws -> Person {
        //same
        guard let personId = req.parameters.get("personId", as: UUID.self) else {
            throw Abort(.notFound)
        }
        //same
        guard let person = try await Person.find(personId, on : req.db) else {
            throw Abort(.notFound, reason: "PersonId \(personId) was not found.")
        }

        return person
    }
    //func getAll
    /*This keyword indicates that the function is asynchronous. 
    It allows the function to perform non-blocking operations, such as database queries, without blocking the main thread.*/
    //This specifies the return type of the function. In this case, the function returns an array of Person objects
    func getAll(req: Request) async throws -> [Person] {
        //This line initiates a query on the Person model
        return try await Person.query(on: req.db)
        // This method is called on the query object and retrieves all records that match the query criteria.
        .all()
    }
    //func for creating person model
    func create(req: Request) async throws -> Person {
        
       let person = try req.content.decode(Person.self)
       try await person.save(on: req.db)
       return person
    }
}