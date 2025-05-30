import vibe.d;
import vibe.http.server;
import vibe.http.router;
import vibe.http.common;
import vibe.core.core;
import vibe.core.log;

shared static this()
{
    auto settings = new HTTPServerSettings;
    settings.port = 8081;
    settings.bindAddresses = ["0.0.0.0"];  // Allow connections from any interface
    
    auto router = new URLRouter;
    router.get("/", &handleRoot);
    router.get("/run", &handleRun);
    
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