#!/bin/bash

# Mostrar encabezado con logo
echo -e "\e[32m"
echo "███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗ ██████╗  ██████╗"
echo "██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔══██╗██╔═══██╗"
echo "███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██████╔╝██║   ██║"
echo "╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔═══╝ ██╔══██╗██║   ██║"
echo "███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║     ██║  ██║╚██████╔╝"
echo "╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ "
echo -e "\e[0m"
echo -e "\e[1;33m🚀 Plataforma de Automatización - SystemBlack\e[0m"
echo "" ""

echo "=== CONFIGURACIÓN INICIAL DE MAUTIC + TRAEFIK ==="

read -p "🔎 Dominio principal para Mautic (ej: mautic.midominio.com): " MAUTIC_DOMAIN
read -p "🔎 Dominio para PhpMyAdmin (ej: pma.midominio.com): " PMA_DOMAIN
read -p "🔎 Correo electrónico para Let's Encrypt: " EMAIL
read -p "🔎 Nombre de la base de datos para Mautic: " DB_NAME
read -p "🔎 Usuario de la base de datos: " DB_USER
read -p "🔎 Contraseña de la base de datos: " DB_PASS

# Confirmación de los datos
clear
echo -e "\n🔍 Verifica que los siguientes datos sean correctos:\n"
echo "Dominio Mautic      : $MAUTIC_DOMAIN"
echo "Dominio PhpMyAdmin  : $PMA_DOMAIN"
echo "Correo Electrónico  : $EMAIL"
echo "DB Nombre           : $DB_NAME"
echo "DB Usuario          : $DB_USER"
echo "DB Contraseña        : $DB_PASS"
echo ""
read -p "✅ ¿Son correctos estos datos? (s/n): " confirm

if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
  echo "❌ Operación cancelada reiniciando."
    sleep 2
    clear
    sleep 2
   ./iniciar_mautic.sh
 
fi



echo "✅ Generando docker-compose.yml..."

cat > docker-compose.yml <<EOF
version: '3.3'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    restart: always
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    command:
      - "--api.dashboard=true"
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--certificatesresolvers.myresolver.acme.httpchallenge=true"
      - "--certificatesresolvers.myresolver.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.myresolver.acme.email=${EMAIL}"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./letsencrypt:/letsencrypt
    networks:
      - mautic-traefik_mautic_net

  mautic:
    image: mautic/mautic:latest
    container_name: mautic
    restart: always
    volumes:
      - mautic_data:/var/www/html
    environment:
      - MAUTIC_DB_HOST=db
      - MAUTIC_DB_PORT=3306
      - MAUTIC_DB_NAME=${DB_NAME}
      - MAUTIC_DB_USER=${DB_USER}
      - MAUTIC_DB_PASSWORD=${DB_PASS}

      - MAUTIC_RUN_CRON_JOBS=true
    depends_on:
      - db
    networks:
      - mautic-traefik_mautic_net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.mautic.rule=Host(\`${MAUTIC_DOMAIN}\`)"
      - "traefik.http.routers.mautic.entrypoints=websecure"
      - "traefik.http.routers.mautic.tls=true"
      - "traefik.http.routers.mautic.tls.certresolver=myresolver"
      - "traefik.http.services.mautic.loadbalancer.server.port=80"

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: pma_mautic
    restart: always
    environment:
      PMA_HOST: db
      MYSQL_ROOT_PASSWORD: rootpass
    depends_on:
      - db
    networks:
      - mautic-traefik_mautic_net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.pma.rule=Host(\`${PMA_DOMAIN}\`)"
      - "traefik.http.routers.pma.entrypoints=websecure"
      - "traefik.http.routers.pma.tls=true"
      - "traefik.http.routers.pma.tls.certresolver=myresolver"
      - "traefik.http.services.pma.loadbalancer.server.port=80"

  db:
    image: mariadb:10.6
    container_name: mautic_db
    restart: always
    volumes:
      - db_data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=rootpass
      - MYSQL_DATABASE=mautic
      - MYSQL_USER=mauticuser
      - MYSQL_PASSWORD=mauticpass
    networks:
      - mautic-traefik_mautic_net

volumes:
  mautic_data:
  db_data:

networks:
  mautic-traefik_mautic_net:
    external: true
EOF

echo "✅ Preparando letsencrypt/acme.json..."
mkdir -p letsencrypt
rm -f letsencrypt/acme.json
touch letsencrypt/acme.json
chmod 600 letsencrypt/acme.json

echo "🚀 Iniciando contenedores con Docker Compose..."
docker compose up -d

echo
echo "🎯 Accede a Mautic en: https://${MAUTIC_DOMAIN}"
echo "🎯 Accede a PhpMyAdmin en: https://${PMA_DOMAIN}"

echo

echo "✅ Finalizando la Instalacion..."
sleep 2
rm -f iniciar_mautic.sh


echo "🚀 Datos de la base de datos de Mautic.."

echo "✅ Nombre Base de Datos: ${DB_NAME}"
echo "✅ Nombre Base de Usuario: ${DB_USER}"
echo "✅ Nombre Base de Contraseña: ${DB_PASS}"


 





