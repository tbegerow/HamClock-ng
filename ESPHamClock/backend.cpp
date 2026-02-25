#include "HamClock.h"
#include "backend.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <sys/stat.h>
#include <unistd.h>

// Backend-Server
bool backend_server_enabled;

static std::string backend_home;

void initBackendServer()
{
    uint8_t val = 0;

    if (NVReadUInt8(NV_BACKEND_ENABLED, &val)) {
        backend_server_enabled = (val != 0);
    } else {
        backend_server_enabled = false;
    }

   // backend_server_enabled = true;

    const char *home = getenv("HOME");
    if (home) {
        std::string path = std::string(home) + "/.hamclock/backend";
        setBackendHome(path.c_str());
    }
}
void setBackendHome(const char *home) {
    backend_home = home;
}
// deliver filesize
static long fileSize(const char *path) {
    struct stat st;
    if (stat(path, &st) != 0)
        return -1;
    return st.st_size;
}

// send 404
static void send404(FILE *sockfp, const char *msg) {
    fprintf(sockfp, "HTTP/1.0 404 Not Found\r\n");
    fprintf(sockfp, "Content-Type: text/plain\r\n\r\n");
    fprintf(sockfp, "File not found: %s\n", msg);
}
void handleBackend(FILE *sockfp, const char *req_url) {
    if (!backend_server_enabled) {
        fprintf(sockfp, "HTTP/1.0 403 Forbidden\r\n");
        fprintf(sockfp, "Content-Type: text/plain\r\n\r\n");
        fprintf(sockfp, "Backend-Server ist nicht aktiviert.\n");
        return;
    }

    const char *path = req_url;
    if (strncmp(req_url, "backend/", 8) == 0) {
        path += 8;
    } else if (strncmp(req_url, "/backend/", 9) == 0) {
        path += 9;
    }

    // Schutz gegen Pfad-Traversal
    if (strstr(path, "..") != nullptr) {
        fprintf(sockfp, "HTTP/1.0 403 Forbidden\r\n");
        fprintf(sockfp, "Content-Type: text/plain\r\n\r\n");
        fprintf(sockfp, "Ungültiger Pfad.\n");
        return;
    }

    char fullpath[512];
    snprintf(fullpath, sizeof(fullpath), "%s/%s", backend_home.c_str(), path);

    // version.txt
    if (strcmp(path, "version.txt") == 0) {
        FILE *f = fopen(fullpath, "r");
        if (!f) {
            send404(sockfp, path);
            return;
        }
        char ver[128];
        if (!fgets(ver, sizeof(ver), f))
            strcpy(ver, "unknown");
        fclose(f);

        fprintf(sockfp, "HTTP/1.0 200 OK\r\n");
        fprintf(sockfp, "Content-Type: text/plain\r\n\r\n");
        fprintf(sockfp, "%s", ver);
        return;
    }

    // sonst: Datei-Download
    FILE *f = fopen(fullpath, "rb");
    if (!f) {
        send404(sockfp, path);
        return;
    }

    long sz = fileSize(fullpath);
    if (sz < 0) sz = 0;

    fprintf(sockfp, "HTTP/1.0 200 OK\r\n");
    fprintf(sockfp, "Content-Type: application/octet-stream\r\n");
    fprintf(sockfp, "Content-Length: %ld\r\n", sz);
    fprintf(sockfp, "Connection: close\r\n\r\n");

    char buf[1024];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), f)) > 0)
        fwrite(buf, 1, n, sockfp);

    fclose(f);
}

// Backend-Client
char backend_host_buf[NV_DATA_HOST_LEN] = "clearskyinstitute.com";
const char *backend_host = backend_host_buf;
int backend_port = 80;
char backend_basepath_buf[NV_DATA_BASEPATH_LEN] = "/";
const char *backend_basepath = backend_basepath_buf;

void initBackendClientConfig()
{
    uint8_t use_remote = 0;

    // 1) NV_USE_REMOTE_BACKEND?
    if (!NVReadUInt8(NV_USE_REMOTE_BACKEND, &use_remote) || !use_remote)
        return;

    // 2) Host
    if (NVReadString(NV_DATA_HOST, backend_host_buf) && backend_host_buf[0]) {
        backend_host = backend_host_buf;
    }

    // 3) Port
    uint16_t port = 0;
    if (NVReadUInt16(NV_DATA_PORT, &port) && port > 0) {
        backend_port = port;
    }
    // 4) Backendpath
    if (NVReadString(NV_DATA_BASEPATH, backend_basepath_buf) && backend_basepath_buf[0]) {
        backend_basepath = backend_basepath_buf;
   }
}
