import vibe.d;
import vibe.http.server;
import vibe.http.router;
import vibe.http.common;
import vibe.core.core;
import vibe.core.log;
import handlers;
import user;
import database;

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
    
    // User CRUD routes
    router.post("/users/random", &handleCreateRandomUser);
    router.get("/users/:id", &handleGetUser);
    router.get("/users", &handleListUsers);
    router.put("/users/:id", &handleUpdateUser);
    router.delete("/users/:id", &handleDeleteUser);
    
    listenHTTP(settings, router);
    logInfo("Server is running on http://0.0.0.0:8081");
}