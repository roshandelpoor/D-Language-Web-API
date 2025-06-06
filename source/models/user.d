import vibe.d;
import std.random;
import std.string;

struct User {
    string username;
    string email;
    int age;
    string country;
    
    // Add validation
    bool isValid() {
        return username.length > 0 &&
               email.length > 0 &&
               age >= 18 &&
               country.length > 0;
    }
}

// Function to generate random user data
User generateRandomUser() {
    string[] countries = ["USA", "Canada", "UK", "Germany", "France", "Japan", "Australia"];
    string[] domains = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com"];
    
    // Generate random username
    string username = "user_" ~ uniform(1000, 9999).to!string;
    
    // Generate random email
    string email = username ~ "@" ~ domains[uniform(0, domains.length)];
    
    // Generate random age between 18 and 80
    int age = uniform(18, 81);
    
    // Select random country
    string country = countries[uniform(0, countries.length)];
    
    return User(username, email, age, country);
} 

 