from http.server import BaseHTTPRequestHandler, HTTPServer

class Redirect(BaseHTTPRequestHandler):
    def _redirect(self):
        host = self.headers.get('Host', '54.145.223.218').split(':')[0]
        self.send_response(301)
        self.send_header('Location', 'https://' + host + self.path)
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
    def do_GET(self):
        self._redirect()
    def do_HEAD(self):
        self._redirect()
    def log_message(self, fmt, *args):
        return

HTTPServer(('0.0.0.0', 80), Redirect).serve_forever()
