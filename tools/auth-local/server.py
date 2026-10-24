"""Local-only stand-in for the supplied central JWT template. No third-party dependencies."""
import base64
import hashlib
import hmac
import json
from pathlib import Path
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import secrets
import time
from urllib.parse import urlencode, parse_qs

ROOT = Path(__file__).resolve().parents[2]
SETTINGS = json.loads((ROOT / '.local/settings.json').read_text(encoding='utf-8-sig'))
SECRET = SETTINGS['LOCAL_JWT_SECRET'].encode()
ACCOUNTS = {}
for name, password in SETTINGS['test_accounts'].items():
    salt = secrets.token_bytes(16)
    ACCOUNTS[name] = (salt, hashlib.pbkdf2_hmac('sha256', password.encode(), salt, 200000))

def token(name):
    def encode(value):
        return base64.urlsafe_b64encode(json.dumps(value, separators=(',', ':')).encode()).rstrip(b'=').decode()
    now = int(time.time())
    message = encode({'alg':'HS256','typ':'JWT'}) + '.' + encode({'sub':name,'iat':now,'exp':now+1800})
    signature = base64.urlsafe_b64encode(hmac.new(SECRET, message.encode(), hashlib.sha256).digest()).rstrip(b'=').decode()
    return message + '.' + signature

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass  # Never log passwords or token URLs.

    def respond(self, status, data, content_type='application/json; charset=utf-8'):
        self.send_response(status)
        self.send_header('Cache-Control','no-store')
        self.send_header('Referrer-Policy','no-referrer')
        self.send_header('Content-Type',content_type)
        self.end_headers()
        self.wfile.write(data.encode())

    def do_GET(self):
        self.respond(200, '''<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Login central local</title>
        <style>body{font:18px Arial;background:#f8f9fa;color:#212529;margin:0}main{max-width:420px;margin:50px auto;padding:26px;background:white;border-radius:12px}h1{color:#007a33}input,button{box-sizing:border-box;width:100%;padding:18px;margin:10px 0 20px;font:inherit;border:1px solid #ccc;border-radius:8px}button{background:#007a33;color:white;border:0}a{color:#007a33}</style>
        <main><h1>Comunidad · Pruebas locales</h1><p>Ingresa con una cuenta de prueba de la plantilla. Al entrar, podrás abrir Rastro Rural.</p><form method="post" action="/entrar"><label>Usuario<input name="nombre_usuario" required autocomplete="username"></label><label>Contraseña<input name="credenciales" type="password" required autocomplete="current-password"></label><button>Entrar a Rastro Rural</button></form></main></html>''', 'text/html; charset=utf-8')

    def do_POST(self):
        if self.path not in ('/api/auth/login','/entrar'):
            self.respond(404, json.dumps({'detail':'Ruta no encontrada'})); return
        length = int(self.headers.get('Content-Length','0'))
        if length > 4096:
            self.respond(413, json.dumps({'detail':'Solicitud demasiado grande'})); return
        try:
            raw = self.rfile.read(length).decode()
            data = json.loads(raw) if self.path == '/api/auth/login' else {k:v[0] for k,v in parse_qs(raw).items()}
            name, password = data.get('nombre_usuario',''), data.get('credenciales','')
            account = ACCOUNTS.get(name)
            if account is None or not hmac.compare_digest(account[1], hashlib.pbkdf2_hmac('sha256', password.encode(), account[0], 200000)):
                self.respond(401, json.dumps({'detail':'Usuario o contraseña incorrectos'})); return
            value = token(name)
            if self.path == '/api/auth/login':
                self.respond(200, json.dumps({'nombre_usuario':name,'access_token':value,'usuario':name,'token':value,'token_type':'bearer','expires_in':1800})); return
            self.send_response(303)
            self.send_header('Cache-Control','no-store')
            self.send_header('Referrer-Policy','no-referrer')
            self.send_header('Location', SETTINGS.get('APP_URL','http://localhost:8080/rastro-rural/')+'?'+urlencode({'usuario':name,'token':value}))
            self.end_headers()
        except (ValueError, TypeError, UnicodeDecodeError):
            self.respond(400, json.dumps({'detail':'Solicitud no válida'}))

if __name__ == '__main__':
    print('Login central de pruebas: http://127.0.0.1:8110', flush=True)
    ThreadingHTTPServer(('127.0.0.1',8110), Handler).serve_forever()
