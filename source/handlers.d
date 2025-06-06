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
import models.user;
import db.database;
import std.conv;

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
        
        res.writeJsonBody([
            "status": "success",
            "message": "Random user created successfully",
            "user": [
                "id": userId,
                "username": randomUser.username,
                "email": randomUser.email,
                "age": randomUser.age,
                "country": randomUser.country
            ]
        ]);
    } catch (Exception e) {
        res.statusCode = HTTPStatus.internalServerError;
        res.writeJsonBody([
            "status": "error",
            "message": e.msg
        ]);
    }
}

void handleGetUser(HTTPServerRequest req, HTTPServerResponse res)
{
    try {
        int userId = to!int(req.params["id"]);
        auto db = new Database();
        
        auto user = db.getUser(userId);
        if (user is null) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody([
                "status": "error",
                "message": "User not found"
            ]);
            return;
        }
        
        res.writeJsonBody([
            "status": "success",
            "user": [
                "username": user.username,
                "email": user.email,
                "age": user.age,
                "country": user.country
            ]
        ]);
    } catch (Exception e) {
        res.statusCode = HTTPStatus.internalServerError;
        res.writeJsonBody([
            "status": "error",
            "message": e.msg
        ]);
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
        
        res.writeJsonBody([
            "status": "success",
            "total": total,
            "limit": limit,
            "offset": offset,
            "users": users.map!(u => [
                "username": u.username,
                "email": u.email,
                "age": u.age,
                "country": u.country
            ]).array
        ]);
    } catch (Exception e) {
        res.statusCode = HTTPStatus.internalServerError;
        res.writeJsonBody([
            "status": "error",
            "message": e.msg
        ]);
    }
}

void handleUpdateUser(HTTPServerRequest req, HTTPServerResponse res)
{
    try {
        int userId = to!int(req.params["id"]);
        auto data = req.jsonBody.to!(string[string]);
        
        auto user = User(
            data["username"],
            data["email"],
            to!int(data["age"]),
            data["country"]
        );
        
        if (!user.isValid()) {
            res.statusCode = HTTPStatus.badRequest;
            res.writeJsonBody([
                "status": "error",
                "message": "Invalid user data"
            ]);
            return;
        }
        
        auto db = new Database();
        if (!db.updateUser(userId, user)) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody([
                "status": "error",
                "message": "User not found"
            ]);
            return;
        }
        
        res.writeJsonBody([
            "status": "success",
            "message": "User updated successfully",
            "user": [
                "username": user.username,
                "email": user.email,
                "age": user.age,
                "country": user.country
            ]
        ]);
    } catch (Exception e) {
        res.statusCode = HTTPStatus.internalServerError;
        res.writeJsonBody([
            "status": "error",
            "message": e.msg
        ]);
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

 