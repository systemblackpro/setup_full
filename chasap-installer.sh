#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
print_message() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[→]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[i]${NC} $1"
}

# Función para verificar si el comando fue exitoso
check_success() {
    if [ $? -eq 0 ]; then
        print_message "$1"
    else
        print_error "$1 - Falló"
        exit 1
    fi
}

# Función para crear separador
separator() {
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════════════════${NC}"
}

# Banner con logo SystemBlack
clear
echo -e "\e[32m"
echo "███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗ ██████╗  ██████╗"
echo "██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔══██╗██╔═══██╗"
echo "███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██████╔╝██║   ██║"
echo "╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔═══╝ ██╔══██╗██║   ██║"
echo "███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║     ██║  ██║╚██████╔╝"
echo "╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ "
echo -e "\e[0m"
echo ""
echo -e "${YELLOW}                    🚀 Plataforma de Automatización - SystemBlack 🚀${NC}"
echo ""
separator
echo -e "${WHITE}                           CHASAP - AUTO INSTALADOR VPS${NC}"
echo -e "${WHITE}                          Whaticket SaaS - Instalación Automática${NC}"
separator
echo ""

# Verificar si está corriendo como root
if [ "$EUID" -ne 0 ]; then
    print_error "Este script debe ejecutarse como root"
    echo -e "${YELLOW}Ejecuta: ${WHITE}sudo $0${NC}"
    exit 1
fi

# Verificar conexión a internet
print_step "Verificando conexión a internet..."
if ping -c 1 google.com &> /dev/null; then
    print_message "Conexión a internet establecida"
else
    print_error "No hay conexión a internet. Verifica tu conexión."
    exit 1
fi

# Verificar sistema operativo
print_step "Verificando sistema operativo..."
if [[ ! -f /etc/os-release ]]; then
    print_error "No se puede determinar el sistema operativo"
    exit 1
fi

OS=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
VERSION=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
print_info "Sistema detectado: $OS $VERSION"

# Verificar si es Ubuntu/Debian
if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    print_error "Este instalador solo soporta Ubuntu/Debian"
    print_info "Sistema recomendado: Ubuntu 24.10 x64"
    exit 1
fi

echo ""
separator
echo -e "${YELLOW}                          CONFIGURACIÓN INICIAL${NC}"
separator
echo ""

# Obtener IP pública del servidor
print_step "Obteniendo IP pública del servidor..."
PUBLIC_IP=$(curl -s https://api.ipify.org)
if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP=$(curl -s https://ipv4.icanhazip.com)
fi
print_info "IP pública detectada: $PUBLIC_IP"

# Recopilar información del usuario
print_step "Configurando parámetros de instalación..."
echo ""

# Configuración básica
echo -e "${CYAN}📋 CONFIGURACIÓN BÁSICA${NC}"
read -p "$(echo -e ${YELLOW}Dominio o IP donde se instalará Chasap ${WHITE}[${PUBLIC_IP}]${NC}: )" DOMAIN
DOMAIN=${DOMAIN:-$PUBLIC_IP}

read -p "$(echo -e ${YELLOW}Puerto para la aplicación ${WHITE}[3000]${NC}: )" PORT
PORT=${PORT:-3000}

echo ""
echo -e "${CYAN}🗄️ CONFIGURACIÓN DE BASE DE DATOS${NC}"
read -p "$(echo -e ${YELLOW}Nombre de la base de datos ${WHITE}[chasap]${NC}: )" DB_NAME
DB_NAME=${DB_NAME:-chasap}

read -p "$(echo -e ${YELLOW}Usuario de la base de datos ${WHITE}[chasap_user]${NC}: )" DB_USER
DB_USER=${DB_USER:-chasap_user}

while true; do
    read -s -p "$(echo -e ${YELLOW}Contraseña de la base de datos${NC}: )" DB_PASSWORD
    echo ""
    if [ -n "$DB_PASSWORD" ]; then
        break
    else
        print_warning "La contraseña no puede estar vacía"
    fi
done

echo ""
echo -e "${CYAN}📱 CONFIGURACIÓN DE WHATSAPP${NC}"
read -p "$(echo -e ${YELLOW}Número de WhatsApp ${WHITE}(ej: +521234567890)${NC}: )" WHATSAPP_NUMBER
read -p "$(echo -e ${YELLOW}Nombre del bot de WhatsApp${NC}: )" BOT_NAME

echo ""
echo -e "${CYAN}👤 CONFIGURACIÓN DE ADMINISTRADOR${NC}"
read -p "$(echo -e ${YELLOW}Email del administrador${NC}: )" ADMIN_EMAIL
while true; do
    read -s -p "$(echo -e ${YELLOW}Contraseña del administrador${NC}: )" ADMIN_PASSWORD
    echo ""
    if [ -n "$ADMIN_PASSWORD" ]; then
        break
    else
        print_warning "La contraseña no puede estar vacía"
    fi
done

echo ""
echo -e "${CYAN}🔐 CONFIGURACIÓN SSL${NC}"
read -p "$(echo -e ${YELLOW}¿Configurar SSL con Let's Encrypt? ${WHITE}[y/N]${NC}: )" SSL_SETUP
SSL_SETUP=${SSL_SETUP:-n}

if [[ "$SSL_SETUP" == "y" || "$SSL_SETUP" == "Y" ]]; then
    read -p "$(echo -e ${YELLOW}Email para Let's Encrypt${NC}: )" SSL_EMAIL
fi

echo ""
separator
echo -e "${YELLOW}                          RESUMEN DE CONFIGURACIÓN${NC}"
separator
echo ""
echo -e "${CYAN}🌐 Dominio/IP:${NC} $DOMAIN"
echo -e "${CYAN}🔌 Puerto:${NC} $PORT"
echo -e "${CYAN}🗄️ Base de datos:${NC} $DB_NAME"
echo -e "${CYAN}👤 Usuario DB:${NC} $DB_USER"
echo -e "${CYAN}📱 WhatsApp:${NC} $WHATSAPP_NUMBER"
echo -e "${CYAN}🤖 Bot:${NC} $BOT_NAME"
echo -e "${CYAN}📧 Admin:${NC} $ADMIN_EMAIL"
echo -e "${CYAN}🔐 SSL:${NC} $SSL_SETUP"
echo ""

read -p "$(echo -e ${YELLOW}¿Continuar con la instalación? ${WHITE}[y/N]${NC}: )" CONTINUE
if [[ $CONTINUE != "y" && $CONTINUE != "Y" ]]; then
    print_warning "Instalación cancelada por el usuario"
    exit 0
fi

echo ""
separator
echo -e "${YELLOW}                          INICIANDO INSTALACIÓN${NC}"
separator
echo ""

# Actualizar sistema
print_step "Actualizando sistema..."
apt update &>/dev/null && apt upgrade -y &>/dev/null
check_success "Sistema actualizado"

# Instalar dependencias básicas
print_step "Instalando dependencias básicas..."
apt install -y curl wget git unzip software-properties-common build-essential &>/dev/null
check_success "Dependencias básicas instaladas"

# Configurar timezone
print_step "Configurando timezone..."
timedatectl set-timezone America/Mexico_City &>/dev/null
check_success "Timezone configurado"

# Instalar Node.js 18.x
print_step "Instalando Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - &>/dev/null
apt install -y nodejs &>/dev/null
check_success "Node.js $(node --version) instalado"

# Instalar PM2
print_step "Instalando PM2..."
npm install -g pm2 &>/dev/null
check_success "PM2 instalado"

# Instalar PostgreSQL
print_step "Instalando PostgreSQL..."
apt install -y postgresql postgresql-contrib &>/dev/null
systemctl start postgresql &>/dev/null
systemctl enable postgresql &>/dev/null
check_success "PostgreSQL instalado"

# Configurar base de datos
print_step "Configurando base de datos..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;" &>/dev/null
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" &>/dev/null
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" &>/dev/null
sudo -u postgres psql -c "ALTER USER $DB_USER CREATEDB;" &>/dev/null
check_success "Base de datos configurada"

# Instalar Nginx
print_step "Instalando Nginx..."
apt install -y nginx &>/dev/null
systemctl start nginx &>/dev/null
systemctl enable nginx &>/dev/null
check_success "Nginx instalado"

# Crear directorio de la aplicación
print_step "Creando directorio de aplicación..."
mkdir -p /var/www/chasap
cd /var/www/chasap
check_success "Directorio creado"

# Clonar repositorio
print_step "Clonando repositorio Chasap..."
git clone https://github.com/MinoruMX/Chasap.git . &>/dev/null
check_success "Repositorio clonado"

# Instalar dependencias de la aplicación
print_step "Instalando dependencias de la aplicación..."
npm install &>/dev/null
check_success "Dependencias instaladas"

# Crear archivo de configuración
print_step "Creando archivo de configuración..."
cat > .env << EOF
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_DIALECT=postgres

# Application Configuration
PORT=$PORT
NODE_ENV=production
DOMAIN=$DOMAIN
URL_BACKEND=http://localhost:$PORT
URL_FRONTEND=http://$DOMAIN

# WhatsApp Configuration
WHATSAPP_NUMBER=$WHATSAPP_NUMBER
BOT_NAME=$BOT_NAME

# Admin Configuration
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD

# Security
JWT_SECRET=$(openssl rand -hex 32)
JWT_REFRESH_SECRET=$(openssl rand -hex 32)
SESSION_SECRET=$(openssl rand -hex 32)

# Redis (opcional)
REDIS_URI=redis://localhost:6379

# CORS
CORS_ORIGIN=http://$DOMAIN
EOF

check_success "Archivo de configuración creado"

# Configurar permisos
print_step "Configurando permisos..."
chown -R www-data:www-data /var/www/chasap
chmod -R 755 /var/www/chasap
check_success "Permisos configurados"

# Configurar Nginx
print_step "Configurando Nginx..."
cat > /etc/nginx/sites-available/chasap << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    client_max_body_size 100M;

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
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }

    # Configuración para archivos estáticos
    location /static/ {
        alias /var/www/chasap/public/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Habilitar sitio
ln -sf /etc/nginx/sites-available/chasap /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Probar configuración de Nginx
nginx -t &>/dev/null
check_success "Configuración de Nginx"

# Reiniciar Nginx
systemctl restart nginx &>/dev/null
check_success "Nginx reiniciado"

# Configurar SSL si se solicitó
if [[ "$SSL_SETUP" == "y" || "$SSL_SETUP" == "Y" ]]; then
    print_step "Configurando SSL con Let's Encrypt..."
    
    # Instalar Certbot
    apt install -y certbot python3-certbot-nginx &>/dev/null
    
    # Obtener certificado SSL
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $SSL_EMAIL &>/dev/null
    check_success "SSL configurado"
    
    # Configurar renovación automática
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    print_info "Renovación automática de SSL configurada"
fi

# Configurar PM2
print_step "Configurando PM2..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'chasap',
    script: './dist/server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: $PORT
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    max_restarts: 5,
    min_uptime: '10s',
    max_memory_restart: '1G'
  }]
};
EOF

# Crear directorio de logs
mkdir -p logs

# Construir aplicación
print_step "Construyendo aplicación..."
npm run build &>/dev/null
check_success "Aplicación construida"

# Iniciar aplicación con PM2
print_step "Iniciando aplicación con PM2..."
pm2 start ecosystem.config.js &>/dev/null
pm2 save &>/dev/null
pm2 startup &>/dev/null
check_success "Aplicación iniciada"

# Configurar firewall
print_step "Configurando firewall..."
ufw --force enable &>/dev/null
ufw allow OpenSSH &>/dev/null
ufw allow 'Nginx Full' &>/dev/null
check_success "Firewall configurado"

# Crear script de utilidades
print_step "Creando script de utilidades..."
cat > /usr/local/bin/chasap << 'EOF'
#!/bin/bash
case $1 in
    start)
        pm2 start chasap
        ;;
    stop)
        pm2 stop chasap
        ;;
    restart)
        pm2 restart chasap
        ;;
    logs)
        pm2 logs chasap
        ;;
    status)
        pm2 status chasap
        ;;
    update)
        cd /var/www/chasap
        git pull
        npm install
        npm run build
        pm2 restart chasap
        ;;
    *)
        echo "Uso: chasap {start|stop|restart|logs|status|update}"
        ;;
esac
EOF

chmod +x /usr/local/bin/chasap
check_success "Script de utilidades creado"

# Mostrar información final
echo ""
separator
echo -e "${GREEN}                    ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE ✅${NC}"
separator
echo ""
echo -e "${CYAN}🔗 Tu aplicación Chasap está disponible en:${NC}"
if [[ "$SSL_SETUP" == "y" || "$SSL_SETUP" == "Y" ]]; then
    echo -e "${WHITE}   https://$DOMAIN${NC}"
else
    echo -e "${WHITE}   http://$DOMAIN${NC}"
fi
echo ""
echo -e "${CYAN}📋 Información de acceso:${NC}"
echo -e "${WHITE}   📧 Email: $ADMIN_EMAIL${NC}"
echo -e "${WHITE}   🔑 Contraseña: [La que configuraste]${NC}"
echo ""
echo -e "${CYAN}🛠️ Comandos útiles:${NC}"
echo -e "${WHITE}   • chasap start    ${NC}- Iniciar aplicación"
echo -e "${WHITE}   • chasap stop     ${NC}- Detener aplicación"
echo -e "${WHITE}   • chasap restart  ${NC}- Reiniciar aplicación"
echo -e "${WHITE}   • chasap logs     ${NC}- Ver logs"
echo -e "${WHITE}   • chasap status   ${NC}- Estado de la aplicación"
echo -e "${WHITE}   • chasap update   ${NC}- Actualizar aplicación"
echo ""
echo -e "${CYAN}📁 Ubicación de archivos:${NC}"
echo -e "${WHITE}   • Aplicación: /var/www/chasap${NC}"
echo -e "${WHITE}   • Logs: /var/www/chasap/logs${NC}"
echo -e "${WHITE}   • Configuración: /var/www/chasap/.env${NC}"
echo ""
separator
echo -e "${GREEN}              🎉 ¡Disfruta tu nueva instalación de Chasap! 🎉${NC}"
separator
echo ""
