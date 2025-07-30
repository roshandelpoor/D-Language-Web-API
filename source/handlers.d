import vibe.d;
import vibe.http.server;
import vibe.http.router;
import vibe.http.common;
import vibe.core.core;
import vibe.core.log;
import std.datetime;
import std.random;
import core.thread;
import std.file;
import std.path;
import vibe.inet.webform;
import std.stdio;
import user;
import database;
import std.conv;
import std.algorithm;
import std.array;
import vibe.data.json;

void handleRoot(HTTPServerRequest req, HTTPServerResponse res)
{
    res.writeJsonBody(["status": "running ..."]);
}

void handleRun(HTTPServerRequest req, HTTPServerResponse res)
{
    res.writeJsonBody(["message": "everything is working"]);
}

void handleTime(HTTPServerRequest req, HTTPServerResponse res)
{
    auto sleepTime = uniform(5, 10);
    Thread.sleep(dur!"seconds"(sleepTime));
    
    auto currentTime = Clock.currTime();
    
    res.writeJsonBody([
        "time": currentTime.toISOExtString()
    ]);
}

void handleFileUpload(HTTPServerRequest req, HTTPServerResponse res)
{
    try {
        if (!exists("uploads")) {
            mkdir("uploads");
        }

        auto pf = "file" in req.files;
        if (pf is null) {
            res.statusCode = HTTPStatus.badRequest;
            res.writeJsonBody(["error": "No file uploaded"]);
            return;
        }
        
        auto timestamp = Clock.currTime().toISOExtString();
        auto destPath = NativePath("uploads") ~ (timestamp ~ "_" ~ pf.filename.to!string);
        
        try moveFile(pf.tempPath, destPath);
        catch (Exception e) {
            logWarn("Failed to move file to destination folder: %s", e.msg);
            logInfo("Performing copy+delete instead.");
            copyFile(pf.tempPath, destPath);
        }

        import std.file : getSize;
        auto fileSize = getSize(destPath.toString());

        string contentType = "";
        static if (__traits(hasMember, typeof(*pf), "contentType"))
            contentType = (*pf).contentType;
        else static if (__traits(hasMember, typeof(*pf), "type"))
            contentType = (*pf).type;
        else static if (__traits(hasMember, typeof(*pf), "mimeType"))
            contentType = (*pf).mimeType;

        res.writeJsonBody([
            "status": "success",
            "filename": destPath.toString(),
            "size": to!string(fileSize),
            "content_type": contentType
        ]);
    } catch (Exception e) {
        res.statusCode = HTTPStatus.internalServerError;
        res.writeJsonBody(["error": e.msg]);
    }
}

void handleCreateRandomUser(HTTPServerRequest req, HTTPServerResponse res)
{
    try {
        auto db = new Database();
        auto randomUser = generateRandomUser();
        
        int userId = db.insertUser(randomUser);
        
        auto userJson = Json([
            "id": Json(userId),
            "username": Json(randomUser.username),
            "email": Json(randomUser.email),
            "age": Json(randomUser.age),
            "country": Json(randomUser.country)
        ]);
        
        res.writeJsonBody(Json([
            "status": Json("success"),
            "message": Json("Random user created successfully"),
            "user": userJson
        ]));
    } catch (Exception e) {
        res.statusCode = HTTPStatus.internalServerError;
        res.writeJsonBody(Json([
            "status": Json("error"),
            "message": Json(e.msg)
        ]));
    }
}

void handleGetUser(HTTPServerRequest req, HTTPServerResponse res)
{
    try {
        int userId = to!int(req.params["id"]);
        auto db = new Database();
        
        auto user = db.getUser(userId);
        if (!user.isNull) {
            auto userJson = Json([
                "username": Json(user.get.username),
                "email": Json(user.get.email),
                "age": Json(user.get.age),
                "country": Json(user.get.country)
            ]);
            
            res.writeJsonBody(Json([
                "status": Json("success"),
                "user": userJson
            ]));
        } else {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(Json([
                "status": Json("error"),
                "message": Json("User not found")
            ]));
        }
    } catch (Exception e) {
        res.statusCode = HTTPStatus.internalServerError;
        res.writeJsonBody(Json([
            "status": Json("error"),
            "message": Json(e.msg)
        ]));
    }
}

void handleListUsers(HTTPServerRequest req, HTTPServerResponse res)
{
    try {
        int limit = to!int(req.params.get("limit", "10"));
        int offset = to!int(req.params.get("offset", "0"));
        
        auto db = new Database();
        auto users = db.listUsers(limit, offset);
        auto total = db.countUsers();
        
        auto userArray = users.map!(u => Json([
            "username": Json(u.username),
            "email": Json(u.email),
            "age": Json(u.age),
            "country": Json(u.country)
        ])).array;
        
        auto userList = Json(userArray);
        
        res.writeJsonBody(Json([
            "status": Json("success"),
            "total": Json(total),
            "limit": Json(limit),
            "offset": Json(offset),
            "users": userList
        ]));
    } catch (Exception e) {
        res.statusCode = HTTPStatus.internalServerError;
        res.writeJsonBody(Json([
            "status": Json("error"),
            "message": Json(e.msg)
        ]));
    }
}

void handleUpdateUser(HTTPServerRequest req, HTTPServerResponse res)
{
    try {
        int userId = to!int(req.params["id"]);
        
        // Read JSON body from request
        auto jsonString = req.bodyReader.readAllUTF8();
        auto data = jsonString.deserializeJson!(string[string]);
        
        auto user = User(
            data["username"],
            data["email"],
            to!int(data["age"]),
            data["country"]
        );
        
        if (!user.isValid()) {
            res.statusCode = HTTPStatus.badRequest;
            res.writeJsonBody(Json([
                "status": Json("error"),
                "message": Json("Invalid user data")
            ]));
            return;
        }
        
        auto db = new Database();
        if (!db.updateUser(userId, user)) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(Json([
                "status": Json("error"),
                "message": Json("User not found")
            ]));
            return;
        }
        
        auto userJson = Json([
            "username": Json(user.username),
            "email": Json(user.email),
            "age": Json(user.age),
            "country": Json(user.country)
        ]);
        
        res.writeJsonBody(Json([
            "status": Json("success"),
            "message": Json("User updated successfully"),
            "user": userJson
        ]));
    } catch (Exception e) {
        res.statusCode = HTTPStatus.internalServerError;
        res.writeJsonBody(Json([
            "status": Json("error"),
            "message": Json(e.msg)
        ]));
    }
}

void handleDeleteUser(HTTPServerRequest req, HTTPServerResponse res)
{
    try {
        int userId = to!int(req.params["id"]);
        auto db = new Database();
        
        if (!db.deleteUser(userId)) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody([
                "status": "error",
                "message": "User not found"
            ]);
            return;
        }
        
        res.writeJsonBody([
            "status": "success",
            "message": "User deleted successfully"
        ]);
    } catch (Exception e) {
        res.statusCode = HTTPStatus.internalServerError;
        res.writeJsonBody([
            "status": "error",
            "message": e.msg
        ]);
    }
} 

 