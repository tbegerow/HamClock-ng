#pragma once
#include <cstdio>

extern bool backend_server_enabled;
extern const char *backend_host;
extern int backend_port;

// Backend home path
void setBackendHome(const char *home);

// Request handler
void handleBackend(FILE *sockfp, const char *req_url);

// Init
void initBackendServer();

// Backend client
void initBackendClientConfig();
