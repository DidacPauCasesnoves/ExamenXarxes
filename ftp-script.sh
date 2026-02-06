#!/bin/bash

# ==========================
# VARIABLES
# ==========================
PASS_LECTURA="12345678"
PASS_ESCRITURA="12345678"

USER_LECTURA="usuariolectura"
USER_ESCRITURA="usuarioescritura"

HOME_LECTURA="/home/$USER_LECTURA"
HOME_ESCRITURA="/home/$USER_ESCRITURA"

DIR_LECTURA="$HOME_LECTURA/ftp"
DIR_ESCRITURA="$HOME_ESCRITURA/ftp"

# ==========================
# ACTUALIZAR SISTEMA
# ==========================
apt update -y

# ==========================
# INSTALAR VSFTPD
# ==========================
apt install vsftpd -y

# ==========================
# CREAR USUARIOS (si no existen)
# ==========================
id -u $USER_LECTURA &>/dev/null || useradd -m -s /bin/bash $USER_LECTURA
id -u $USER_ESCRITURA &>/dev/null || useradd -m -s /bin/bash $USER_ESCRITURA

echo "$USER_LECTURA:$PASS_LECTURA" | chpasswd
echo "$USER_ESCRITURA:$PASS_ESCRITURA" | chpasswd

# ==========================
# CREAR DIRECTORIOS FTP
# ==========================
mkdir -p $DIR_LECTURA
mkdir -p $DIR_ESCRITURA

# ==========================
# PERMISOS USUARIO LECTURA
# ==========================
chown root:root $HOME_LECTURA
chmod 755 $HOME_LECTURA

chown $USER_LECTURA:$USER_LECTURA $DIR_LECTURA
chmod 555 $DIR_LECTURA   # solo lectura

# ==========================
# PERMISOS USUARIO ESCRITURA
# ==========================
chown root:root $HOME_ESCRITURA
chmod 755 $HOME_ESCRITURA

chown $USER_ESCRITURA:$USER_ESCRITURA $DIR_ESCRITURA
chmod 755 $DIR_ESCRITURA   # lectura y escritura

# ==========================
# CONFIGURAR VSFTPD
# ==========================
cp /etc/vsftpd.conf /etc/vsftpd.conf.bak

cat <<EOF > /etc/vsftpd.conf
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=10000
pasv_max_port=10100
user_sub_token=\$USER
local_root=/home/\$USER/ftp
EOF

# ==========================
# REINICIAR SERVICIO
# ==========================
systemctl restart vsftpd
systemctl enable vsftpd

# ==========================
# MENSAJE FINAL
# ==========================
echo "✅ FTP configurado correctamente"
echo "👤 Usuario lectura: $USER_LECTURA (solo lectura)"
echo "👤 Usuario escritura: $USER_ESCRITURA (lectura y escritura)"