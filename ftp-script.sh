#!/bin/bash

# ==========================
# 1. ZONA DE EDICION (CAMBIA ESTO EN EL EXAMEN)
# ==========================
# Si el examen dice: "Crea usuari1 (lectura) y usuari2 (escriptura)"
USER_LECTURA="usuari1"       # <--- CAMBIAR NOMBRE
PASS_LECTURA="1234rewq"      # <--- CAMBIAR CONTRASENA

USER_ESCRITURA="usuari2"     # <--- CAMBIAR NOMBRE
PASS_ESCRITURA="1234rewq"    # <--- CAMBIAR CONTRASENA

# Rutas (No hace falta tocarlas normalmente)
HOME_LECTURA="/home/$USER_LECTURA"
HOME_ESCRITURA="/home/$USER_ESCRITURA"
DIR_LECTURA="$HOME_LECTURA/ftp"
DIR_ESCRITURA="$HOME_ESCRITURA/ftp"

# ==========================
# 2. INSTALACION
# ==========================
echo "--- Instalando VSFTPD ---"
apt update -y
apt install vsftpd -y

# ==========================
# 3. CREAR USUARIOS
# ==========================
echo "--- Creando usuarios ---"
# Crea usuario lectura si no existe
id -u $USER_LECTURA &>/dev/null || useradd -m -s /bin/bash $USER_LECTURA
# Crea usuario escritura si no existe
id -u $USER_ESCRITURA &>/dev/null || useradd -m -s /bin/bash $USER_ESCRITURA

# Asignar contraseñas
echo "$USER_LECTURA:$PASS_LECTURA" | chpasswd
echo "$USER_ESCRITURA:$PASS_ESCRITURA" | chpasswd

# ==========================
# 4. PREPARAR CARPETAS Y PERMISOS
# ==========================================
echo "--- Configurando permisos ---"

mkdir -p $DIR_LECTURA
mkdir -p $DIR_ESCRITURA

# --- USUARIO LECTURA ---
# El home es de root (obligatorio para chroot)
chown root:root $HOME_LECTURA
chmod 755 $HOME_LECTURA
# La carpeta ftp es del usuario pero SIN permisos de escritura (555)
chown $USER_LECTURA:$USER_LECTURA $DIR_LECTURA
chmod 555 $DIR_LECTURA  

# --- USUARIO ESCRITURA ---
# El home es de root (obligatorio para chroot)
chown root:root $HOME_ESCRITURA
chmod 755 $HOME_ESCRITURA
# La carpeta ftp es del usuario CON permisos de escritura (755)
chown $USER_ESCRITURA:$USER_ESCRITURA $DIR_ESCRITURA
chmod 755 $DIR_ESCRITURA 

# ==========================
# 5. CONFIGURAR VSFTPD
# ==========================
cp /etc/vsftpd.conf /etc/vsftpd.conf.bak

# Configuracion basada en PDF pag 8 y adaptada
cat <<EOF > /etc/vsftpd.conf
listen=YES
# listen_ipv6=NO  <-- A veces da error si no tienes IPv6, mejor comentado o NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES

# JAULA (CHROOT)
chroot_local_user=YES
allow_writeable_chroot=YES

# RUTA PERSONALIZADA (Van directos a la carpeta /ftp)
user_sub_token=\$USER
local_root=/home/\$USER/ftp
EOF

# ==========================
# 6. REINICIAR
# ==========================
systemctl restart vsftpd
systemctl enable vsftpd
systemctl status vsftpd --no-pager

echo "✅ FTP configurado correctamente"
echo "--- DATOS ---"
echo "Lectura:   $USER_LECTURA (Pass: $PASS_LECTURA)"
echo "Escritura: $USER_ESCRITURA (Pass: $PASS_ESCRITURA)"
