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

shared static this()
{
    auto settings = new HTTPServerSettings;
    settings.port = 8081;
    settings.bindAddresses = ["0.0.0.0"];
    
    auto router = new URLRouter;
    router.get("/", &handleRoot);
    router.get("/run", &handleRun);
    router.get("/time", &handleTime);
    router.post("/upload", &handleFileUpload);
    
    listenHTTP(settings, router);
    logInfo("Server is running on http://0.0.0.0:8081");
}

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
        "time": currentTime.toISOExtString(),
        "sleep_duration": sleepTime
    ]);
}

void handleFileUpload(HTTPServerRequest req, HTTPServerResponse res)
{
    try {
        if (!exists("uploads")) {
            mkdir("uploads");
        }

        auto file = req.files["file"];
        if (file is null) {
            res.statusCode = HTTPStatus.badRequest;
            res.writeJsonBody(["error": "No file uploaded"]);
            return;
        }

        auto timestamp = Clock.currTime().toISOExtString();
        auto filename = "uploads/" ~ timestamp ~ "_" ~ file.filename;
        
        file.saveAs(filename);
        
        res.writeJsonBody([
            "status": "success",
            "filename": filename,
            "size": file.size,
            "content_type": file.contentType
        ]);
    } catch (Exception e) {
        res.statusCode = HTTPStatus.internalServerError;
        res.writeJsonBody(["error": e.msg]);
    }
}