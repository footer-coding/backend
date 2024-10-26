import Vapor
import Fluent
//class called Person
final class Person: Model, Content{
    //here i write the name of a model
    static let schema = "person"
    //all required inputs
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "lname")
    var lname: String

    @Field(key: "age")
    var age: Int

    @Field(key: "city")
    var city: String
    //default initalizer (always)
    init() { }
    //created initalizer
    init(id: UUID? = nil, name: String, lname: String, age: Int, city:String ) {
        self.id = id //self means that a init use created property id, name etc.
        self.name = name
        self.lname = lname
        self.age = age
        self.city = city
    }
}