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

 