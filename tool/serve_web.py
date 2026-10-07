#!/usr/bin/env python3
"""Serves a Flutter web build for local preview, telling the browser not to
cache anything, so a reload after `flutter build web` always shows the new
build.

    python3 tool/serve_web.py [port] [directory]

Defaults: port 8787, directory example/build/web.
"""

import functools
import http.server
import sys


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    # Without a cached copy there is nothing to revalidate: always send the
    # file, never 304.
    def send_head(self):
        for name in ("If-Modified-Since", "If-None-Match"):
            del self.headers[name]
        return super().send_head()


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8787
    directory = sys.argv[2] if len(sys.argv) > 2 else "example/build/web"
    handler = functools.partial(NoCacheHandler, directory=directory)
    with http.server.ThreadingHTTPServer(("", port), handler) as server:
        print(f"Serving {directory} at http://localhost:{port} (no cache)")
        server.serve_forever()


if __name__ == "__main__":
    main()
