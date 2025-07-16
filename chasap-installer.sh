#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Función para verificar si el comando fue exitoso
check_success() {
    if [ $? -eq 0 ]; then
        print_message "$1 completado exitosamente"
    else
        print_error "$1 falló"
        exit 1
    fi
}

# Banner con logo SystemBlack
echo -e "\e[32m"
echo "███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗ ██████╗  ██████╗"
echo "██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔══██╗██╔═══██╗"
echo "███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██████╔╝██║   ██║"
echo "╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔═══╝ ██╔══██╗██║   ██║"
echo "███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║     ██║  ██║╚██████╔╝"
echo "╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ "
echo -e "\e[0m"
echo -e "\e[1;33m🚀 Plataforma de Automatización - SystemBlack\e[0m"
echo ""
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}    AUTO INSTALADOR CHASAP${NC}"
echo -e "${BLUE}    Instalador automático para VPS${NC}"
echo -e "${BLUE}=============================================${NC}"
echo

# Verificar si está corriendo como root
if [ "$EUID" -ne 0 ]; then
    print_error "Este script debe ejecutarse como root"
    echo "Usa: sudo $0"
    exit 1
fi

# Verificar sistema operativo
if [[ ! -f /etc/os-release ]]; then
    print_error "No se puede determinar el sistema operativo"
    exit 1
fi

OS=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
print_message "Sistema operativo detectado: $OS"

# Recopilar información del usuario
print_step "Recopilando información de configuración..."
echo

# Configuración básica
read -p "Ingresa el dominio o IP donde se instalará Chasap: " DOMAIN
read -p "Ingresa el puerto para la aplicación (por defecto 3000): " PORT
PORT=${PORT:-3000}

# Configuración de base de datos
echo
print_step "Configuración de Base de Datos"
read -p "Nombre de la base de datos (por defecto: chasap): " DB_NAME
DB_NAME=${DB_NAME:-chasap}
read -p "Usuario de la base de datos (por defecto: chasap_user): " DB_USER
DB_USER=${DB_USER:-chasap_user}
read -s -p "Contraseña de la base de datos: " DB_PASSWORD
echo

# Configuración de WhatsApp
echo
print_step "Configuración de WhatsApp"
read -p "Número de teléfono de WhatsApp (con código de país, ej: +521234567890): " WHATSAPP_NUMBER
read -p "Nombre del bot de WhatsApp: " BOT_NAME

# Configuración de administrador
echo
print_step "Configuración de Administrador"
read -p "Email del administrador: " ADMIN_EMAIL
read -s -p "Contraseña del administrador: " ADMIN_PASSWORD
echo

# Configuración SSL
echo
print_step "Configuración SSL"
read -p "¿Quieres configurar SSL con Let's Encrypt? (y/n): " SSL_SETUP
read -p "Email para Let's Encrypt (si elegiste SSL): " SSL_EMAIL

# Mostrar resumen
echo
print_step "Resumen de configuración:"
echo "- Dominio/IP: $DOMAIN"
echo "- Puerto: $PORT"
echo "- Base de datos: $DB_NAME"
echo "- Usuario DB: $DB_USER"
echo "- Número WhatsApp: $WHATSAPP_NUMBER"
echo "- Bot Name: $BOT_NAME"
echo "- Admin Email: $ADMIN_EMAIL"
echo "- SSL: $SSL_SETUP"
echo

read -p "¿Continuar con la instalación? (y/n): " CONTINUE
if [[ $CONTINUE != "y" && $CONTINUE != "Y" ]]; then
    print_warning "Instalación cancelada por el usuario"
    exit 0
fi

# Actualizar sistema
print_step "Actualizando sistema..."
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    apt update && apt upgrade -y
    check_success "Actualización del sistema"
elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
    yum update -y
    check_success "Actualización del sistema"
else
    print_error "Sistema operativo no soportado: $OS"
    exit 1
fi

# Instalar dependencias básicas
print_step "Instalando dependencias básicas..."
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    apt install -y curl wget git unzip software-properties-common
    check_success "Instalación de dependencias básicas"
elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
    yum install -y curl wget git unzip epel-release
    check_success "Instalación de dependencias básicas"
fi

# Instalar Node.js
print_step "Instalando Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    apt install -y nodejs
elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
    yum install -y nodejs npm
fi
check_success "Instalación de Node.js"

# Verificar instalación de Node.js
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
print_message "Node.js instalado: $NODE_VERSION"
print_message "NPM instalado: $NPM_VERSION"

# Instalar PM2
print_step "Instalando PM2..."
npm install -g pm2
check_success "Instalación de PM2"

# Instalar PostgreSQL
print_step "Instalando PostgreSQL..."
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    apt install -y postgresql postgresql-contrib
elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
    yum install -y postgresql-server postgresql-contrib
    postgresql-setup initdb
fi

systemctl start postgresql
systemctl enable postgresql
check_success "Instalación de PostgreSQL"

# Configurar base de datos
print_step "Configurando base de datos..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
check_success "Configuración de base de datos"

# Instalar Nginx
print_step "Instalando Nginx..."
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    apt install -y nginx
elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
    yum install -y nginx
fi

systemctl start nginx
systemctl enable nginx
check_success "Instalación de Nginx"

# Crear directorio de la aplicación
print_step "Creando directorio de aplicación..."
mkdir -p /var/www/chasap
cd /var/www/chasap

# Clonar repositorio
print_step "Clonando repositorio Chasap..."
git clone https://github.com/MinoruMX/Chasap.git .
check_success "Clonación del repositorio"

# Instalar dependencias de la aplicación
print_step "Instalando dependencias de la aplicación..."
npm install
check_success "Instalación de dependencias"

# Crear archivo de configuración
print_step "Creando archivo de configuración..."
cat > .env << EOF
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD

# Application Configuration
PORT=$PORT
NODE_ENV=production
DOMAIN=$DOMAIN

# WhatsApp Configuration
WHATSAPP_NUMBER=$WHATSAPP_NUMBER
BOT_NAME=$BOT_NAME

# Admin Configuration
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD

# Security
JWT_SECRET=$(openssl rand -hex 32)
SESSION_SECRET=$(openssl rand -hex 32)
EOF

check_success "Creación del archivo de configuración"

# Configurar permisos
print_step "Configurando permisos..."
chown -R www-data:www-data /var/www/chasap
chmod -R 755 /var/www/chasap
check_success "Configuración de permisos"

# Configurar Nginx
print_step "Configurando Nginx..."
cat > /etc/nginx/sites-available/chasap << EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Habilitar sitio
ln -s /etc/nginx/sites-available/chasap /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Probar configuración de Nginx
nginx -t
check_success "Configuración de Nginx"

# Reiniciar Nginx
systemctl restart nginx
check_success "Reinicio de Nginx"

# Configurar SSL si se solicitó
if [[ "$SSL_SETUP" == "y" || "$SSL_SETUP" == "Y" ]]; then
    print_step "Configurando SSL con Let's Encrypt..."
    
    # Instalar Certbot
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt install -y certbot python3-certbot-nginx
    elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
        yum install -y certbot python3-certbot-nginx
    fi
    
    # Obtener certificado SSL
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $SSL_EMAIL
    check_success "Configuración SSL"
    
    # Configurar renovación automática
    crontab -l 2>/dev/null | { cat; echo "0 12 * * * /usr/bin/certbot renew --quiet"; } | crontab -
fi

# Configurar PM2
print_step "Configurando PM2..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'chasap',
    script: 'app.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: $PORT
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF

# Crear directorio de logs
mkdir -p logs

# Iniciar aplicación con PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup
check_success "Configuración de PM2"

# Configurar firewall
print_step "Configurando firewall..."
if command -v ufw &> /dev/null; then
    ufw allow OpenSSH
    ufw allow 'Nginx Full'
    ufw --force enable
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
fi
check_success "Configuración del firewall"

# Mostrar información final
echo
print_message "============================================="
print_message "    INSTALACIÓN COMPLETADA EXITOSAMENTE"
print_message "============================================="
echo
print_message "Tu aplicación Chasap está ahora disponible en:"
if [[ "$SSL_SETUP" == "y" || "$SSL_SETUP" == "Y" ]]; then
    print_message "🔗 https://$DOMAIN"
else
    print_message "🔗 http://$DOMAIN"
fi
echo
print_message "Información de acceso:"
print_message "📧 Email: $ADMIN_EMAIL"
print_message "🔑 Contraseña: [La que configuraste]"
echo
print_message "Comandos útiles:"
print_message "• Ver logs: pm2 logs chasap"
print_message "• Reiniciar app: pm2 restart chasap"
print_message "• Estado de la app: pm2 status"
print_message "• Reiniciar Nginx: systemctl restart nginx"
echo
print_message "¡Disfruta tu nueva instalación de Chasap!"
echo
