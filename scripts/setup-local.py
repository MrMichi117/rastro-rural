"""Prepare an isolated local MySQL schema and private settings. Does not connect to Dokploy."""
import argparse
import json
from pathlib import Path
import secrets
import subprocess

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--mysql', default=r'C:/Program Files/MySQL/MySQL Server 8.0/bin/mysql.exe')
parser.add_argument('--port', type=int, default=3310)
args = parser.parse_args()
settings_file = root/'.local/settings.json'
settings_file.parent.mkdir(exist_ok=True)
settings = json.loads(settings_file.read_text(encoding='utf-8-sig')) if settings_file.exists() else {}
password = settings.get('DB_PASSWORD', secrets.token_hex(24))
client = [args.mysql,'--no-defaults','--protocol=TCP','--host=127.0.0.1',f'--port={args.port}','--user=root','--batch','--skip-column-names']
def sql(text, schema=None):
    result = subprocess.run(client+([schema] if schema else []), input=text, text=True, encoding='utf-8', capture_output=True)
    if result.returncode:
        raise SystemExit('MySQL no pudo preparar el esquema local. Verifica el puerto y MYSQL_PWD del administrador. No se mostraron credenciales.')
    return result.stdout.strip()
sql("CREATE DATABASE IF NOT EXISTS rastro_rural_local CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;")
count = sql("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='rastro_rural_local';")
if count == '0':
    sql((root/'database/001_schema.sql').read_text(encoding='utf-8'), 'rastro_rural_local')
elif sql("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='rastro_rural_local' AND table_name='reporte' AND column_name='usuario_emisor';") != '1':
    raise SystemExit('El esquema local contiene una versión anterior. Haz un respaldo antes de migrar; no se alteraron sus tablas.')
sql(f"CREATE USER IF NOT EXISTS 'rastro_local'@'localhost' IDENTIFIED BY '{password}'; ALTER USER 'rastro_local'@'localhost' IDENTIFIED BY '{password}'; GRANT SELECT,INSERT,UPDATE ON rastro_rural_local.* TO 'rastro_local'@'localhost';")
settings.update({
    'DB_URL':f'jdbc:mysql://127.0.0.1:{args.port}/rastro_rural_local?sslMode=DISABLED&allowPublicKeyRetrieval=true&connectionTimeZone=-05:00&forceConnectionTimeZoneToSession=true',
    'DB_USER':'rastro_local', 'DB_PASSWORD':password,
    'LOCAL_JWT_SECRET':settings.get('LOCAL_JWT_SECRET',secrets.token_hex(32)),
    'LOCAL_AUTH_ISSUER':'urn:rastro:local-central',
    'CENTRAL_LOGIN_URL':'http://127.0.0.1:8110/', 'CENTRAL_DASHBOARD_URL':'http://127.0.0.1:8110/',
    'APP_URL':'http://localhost:8080/rastro-rural/', 'PORT':'8080',
    'test_accounts':settings.get('test_accounts',{})
})
settings_file.write_text(json.dumps(settings,indent=2,ensure_ascii=False),encoding='utf-8')
print('Base local lista: 127.0.0.1:'+str(args.port)+'/rastro_rural_local. Configuración privada en .local/settings.json.')
if not settings['test_accounts']:
    print('Agrega las cuentas de prueba de la plantilla en test_accounts del archivo privado antes de iniciar tools/auth-local/server.py.')
