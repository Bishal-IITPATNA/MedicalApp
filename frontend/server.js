/**
 * Minimal static file server (no deps) for Flutter Web build.
 * Serves files from ./web_dist and falls back to /index.html for SPA routes.
 *
 * Listens on $PORT (default 3000) at $HOST (default 0.0.0.0).
 */

const http = require("http");
const fs = require("fs");
const path = require("path");
const url = require("url");

const ROOT = path.join(__dirname, "web_dist");
const PORT = parseInt(process.env.PORT || "3000", 10);
const HOST = process.env.HOST || "0.0.0.0";

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".mjs": "application/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".gif": "image/gif",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".webp": "image/webp",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".ttf": "font/ttf",
  ".otf": "font/otf",
  ".wasm": "application/wasm",
  ".map": "application/json; charset=utf-8",
  ".txt": "text/plain; charset=utf-8",
};

function safeJoin(root, target) {
  const resolved = path.normalize(path.join(root, target));
  if (!resolved.startsWith(root)) return null;
  return resolved;
}

function send(res, status, headers, body) {
  res.writeHead(status, headers);
  if (body && typeof body.pipe === "function") {
    body.pipe(res);
  } else {
    res.end(body);
  }
}

const server = http.createServer((req, res) => {
  const parsed = url.parse(req.url);
  let pathname = decodeURIComponent(parsed.pathname || "/");

  if (pathname === "/healthz") {
    return send(
      res,
      200,
      { "Content-Type": "application/json" },
      JSON.stringify({ status: "ok" })
    );
  }

  if (pathname === "/") pathname = "/index.html";

  let filePath = safeJoin(ROOT, pathname);
  if (!filePath) {
    return send(res, 400, { "Content-Type": "text/plain" }, "Bad request");
  }

  fs.stat(filePath, (err, stat) => {
    if (err || !stat.isFile()) {
      // SPA fallback: serve index.html for non-asset paths
      if (!path.extname(pathname)) {
        const fallback = path.join(ROOT, "index.html");
        return fs.stat(fallback, (e2, s2) => {
          if (e2 || !s2.isFile()) {
            return send(
              res,
              404,
              { "Content-Type": "text/plain" },
              "Not found"
            );
          }
          send(
            res,
            200,
            {
              "Content-Type": MIME[".html"],
              "Cache-Control": "no-cache",
            },
            fs.createReadStream(fallback)
          );
        });
      }
      return send(res, 404, { "Content-Type": "text/plain" }, "Not found");
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME[ext] || "application/octet-stream";
    const isHtml = ext === ".html";
    const headers = {
      "Content-Type": contentType,
      "Content-Length": stat.size,
      "Cache-Control": isHtml
        ? "no-cache"
        : "public, max-age=31536000, immutable",
    };
    send(res, 200, headers, fs.createReadStream(filePath));
  });
});

server.listen(PORT, HOST, () => {
  console.log(`Seevak Care frontend listening on http://${HOST}:${PORT}`);
  console.log(`Serving static files from ${ROOT}`);
});
