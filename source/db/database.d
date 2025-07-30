import vibe.d;
import user;
import std.conv;
import std.typecons;
import std.random;
import std.algorithm;

class Database {
    private static User[] users;
    private static int nextId = 1;
    
    this() {
        // Initialize with some sample data
        if (users.length == 0) {
            users ~= User("john_doe", "john@example.com", 30, "USA");
            users ~= User("jane_smith", "jane@example.com", 25, "Canada");
            users ~= User("bob_wilson", "bob@example.com", 35, "UK");
            nextId = 4;
        }
    }
    
    // Create
    int insertUser(User user) {
        users ~= user;
        return nextId++;
    }
    
    // Read (Single User)
    Nullable!User getUser(int id) {
        if (id <= 0 || id > users.length) {
            return Nullable!User.init;
        }
        return Nullable!User(users[id - 1]);
    }
    
    // Read (List Users)
    User[] listUsers(int limit = 10, int offset = 0) {
        User[] result;
        int start = offset;
        int end = min(start + limit, cast(int)users.length);
        
        for (int i = start; i < end; i++) {
            result ~= users[i];
        }
        
        return result;
    }
    
    // Update
    bool updateUser(int id, User user) {
        if (id <= 0 || id > users.length) {
            return false;
        }
        users[id - 1] = user;
        return true;
    }
    
    // Delete
    bool deleteUser(int id) {
        if (id <= 0 || id > users.length) {
            return false;
        }
        users = users[0..id-1] ~ users[id..$];
        return true;
    }
    
    // Count total users
    int countUsers() {
        return cast(int)users.length;
    }
} 

 