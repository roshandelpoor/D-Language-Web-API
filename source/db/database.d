import vibe.d;
import vibe.db.postgres;
import models.user;
import std.conv;

class Database {
    private PostgreSQLConnection conn;
    
    this() {
        string connString = "postgresql://%s:%s@database:5432/%s"
            .format(environment.get("DB_USERNAME"),
                   environment.get("DB_PASSWORD"),
                   environment.get("DB_DATABASE"));
        conn = new PostgreSQLConnection(connString);
    }
    
    // Create
    int insertUser(User user) {
        string query = `
            INSERT INTO users (username, email, age, country)
            VALUES ($1, $2, $3, $4)
            RETURNING id
        `;
        
        auto result = conn.exec(query, user.username, user.email, user.age, user.country);
        return result[0][0].to!int;
    }
    
    // Read (Single User)
    User? getUser(int id) {
        string query = `
            SELECT id, username, email, age, country, created_at
            FROM users
            WHERE id = $1
        `;
        
        auto result = conn.exec(query, id);
        if (result.length == 0) return null;
        
        return User(
            result[0][1].to!string,  // username
            result[0][2].to!string,  // email
            result[0][3].to!int,     // age
            result[0][4].to!string   // country
        );
    }
    
    // Read (List Users)
    User[] listUsers(int limit = 10, int offset = 0) {
        string query = `
            SELECT id, username, email, age, country, created_at
            FROM users
            ORDER BY created_at DESC
            LIMIT $1 OFFSET $2
        `;
        
        auto result = conn.exec(query, limit, offset);
        User[] users;
        
        foreach (row; result) {
            users ~= User(
                row[1].to!string,  // username
                row[2].to!string,  // email
                row[3].to!int,     // age
                row[4].to!string   // country
            );
        }
        
        return users;
    }
    
    // Update
    bool updateUser(int id, User user) {
        string query = `
            UPDATE users
            SET username = $1,
                email = $2,
                age = $3,
                country = $4
            WHERE id = $5
            RETURNING id
        `;
        
        auto result = conn.exec(query, 
            user.username,
            user.email,
            user.age,
            user.country,
            id
        );
        
        return result.length > 0;
    }
    
    // Delete
    bool deleteUser(int id) {
        string query = `
            DELETE FROM users
            WHERE id = $1
            RETURNING id
        `;
        
        auto result = conn.exec(query, id);
        return result.length > 0;
    }
    
    // Count total users
    int countUsers() {
        string query = "SELECT COUNT(*) FROM users";
        auto result = conn.exec(query);
        return result[0][0].to!int;
    }
} 

 