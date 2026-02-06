#!/bin/bash

# ==========================================
# 1. ZONA DE EDICION (LO MAS IMPORTANTE)
# ==========================================

# 1. Nombres de las webs (Mira el enunciado del examen)
DOMINIO_1="www.intranet.viralup.com"  # <--- CAMBIAR POR EL DOMINIO 1 DEL EXAMEN
DOMINIO_2="www.sistema.viralup.com"   # <--- CAMBIAR POR EL DOMINIO 2 DEL EXAMEN

# 2. Tu Red (Para permitir el acceso a la zona privada)
# Si tu IP es 10.18.51.70, tu red es 10.18.51.0/24. 
# Si tu IP es 192.168.10.5, tu red es 192.168.10.0/24.
IP_RED="10.18.51.0/24"                # <--- CAMBIAR POR TU RED (CUIDADO CON EL /24)

# 3. Carpetas (Solo cámbialas si el profesor te pide rutas raras)
ROOT_1="/var/www/appintranet"         # <--- CAMBIAR SI TE PIDEN OTRA CARPETA
ROOT_2="/var/www/appsistema"          # <--- CAMBIAR SI TE PIDEN OTRA CARPETA
PRIV_1="/srv/www/appintranet/privado" # <--- CAMBIAR SI TE PIDEN OTRA CARPETA

# ==========================================
# 2. INSTALACION (NO TOCAR)
# ==========================================
echo "--- Instalando Apache y utilidades ---"
apt update && apt install apache2 apache2-utils -y
a2enmod ssl cgi alias auth_basic authn_file authz_user authz_core
mkdir -p $ROOT_1/logs $ROOT_2/logs $PRIV_1 /etc/apache2/ssl

echo "<h1>Web Intranet Segura (HTTPS)</h1>" > $ROOT_1/index.html
echo "<h1>Error 404 Personalizado</h1>" > $ROOT_1/404.html
echo "<h1>ZONA PRIVADA - Solo con contrasena</h1>" > $PRIV_1/index.html

# ==========================================
# 3. CERTIFICADO SSL (NO TOCAR EXCEPTO SI PIDEN PAIS/CIUDAD)
# ==========================================
echo "--- Generando certificado SSL ---"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/apache2/ssl/apache.key \
  -out /etc/apache2/ssl/apache.crt \
  -subj "/C=ES/ST=Baleares/L=Palma/O=Examen/CN=$DOMINIO_1" 
  # SI SON MUY ESTRICTOS, CAMBIA LO DE ARRIBA: C=Pais, L=Ciudad, O=Organizacion

# ==========================================
# 4. USUARIOS (MIRA LA TABLA DE USUARIOS DEL EXAMEN)
# ==========================================
echo "--- Creando usuarios ---"
# El formato es: nombre password
htpasswd -bc /etc/apache2/.htpasswd_intra Usuari01 1234  # <--- CAMBIAR NOMBRE Y PASS
htpasswd -b /etc/apache2/.htpasswd_intra Usuari02 1234   # <--- CAMBIAR NOMBRE Y PASS

# ==========================================
# 5. CONFIGURACION VIRTUALHOSTS (NO TOCAR NADA A PARTIR DE AQUI)
# ==========================================

# WEB 1: Intranet
cat <<EOF > /etc/apache2/sites-available/appintranet-ssl.conf
<VirtualHost *:443>
    ServerName $DOMINIO_1
    DocumentRoot $ROOT_1
    
    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/apache.crt
    SSLCertificateKeyFile /etc/apache2/ssl/apache.key

    ErrorDocument 404 /404.html
    ErrorLog $ROOT_1/logs/error.log

    Alias /privado $PRIV_1
    <Directory $PRIV_1>
        AuthType Basic
        AuthName "Acces Restringit"
        AuthUserFile /etc/apache2/.htpasswd_intra
        <RequireAll>
            Require valid-user
            Require ip $IP_RED
        </RequireAll>
    </Directory>
</VirtualHost>
EOF

# WEB 2: Sistema
cat <<EOF > /etc/apache2/sites-available/appsistema-ssl.conf
<VirtualHost *:443>
    ServerName $DOMINIO_2
    DocumentRoot $ROOT_2
    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/apache.crt
    SSLCertificateKeyFile /etc/apache2/ssl/apache.key

    <Directory $ROOT_2>
        Options +ExecCGI
        AddHandler cgi-script .sh
        Require all granted
    </Directory>
</VirtualHost>
EOF

# ==========================================
# 6. ACTIVAR Y REINICIAR (NO TOCAR)
# ==========================================
chown -R www-data:www-data /var/www/ /srv/www/
a2dissite 000-default
a2ensite appintranet-ssl.conf appsistema-ssl.conf
systemctl restart apache2

echo "--- INSTALACION COMPLETADA ---"
echo "IMPORTANTE: En el CLIENTE anade esto a /etc/hosts:"
echo "IP_DEL_SERVIDOR  $DOMINIO_1 $DOMINIO_2"
