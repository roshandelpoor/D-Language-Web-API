import vibe.d;
import vibe.db.postgres;
import models.user;

class Database {
    private PostgreSQLConnection conn;
    
    this() {
        string connString = "postgresql://%s:%s@database:5432/%s"
            .format(environment.get("DB_USERNAME"),
                   environment.get("DB_PASSWORD"),
                   environment.get("DB_DATABASE"));
                   
        conn = new PostgreSQLConnection(connString);
    }
    
    void insertUser(User user) {
        string query = `
            INSERT INTO users (username, email, age, country)
            VALUES ($1, $2, $3, $4)
            RETURNING id
        `;
        
        auto result = conn.exec(query, user.username, user.email, user.age, user.country);
        return result[0][0].to!int;
    }
} 

 