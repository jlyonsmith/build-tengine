#!/usr/bin/env bash
# Run as root or with sudo
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root or with sudo."
  exit 1
fi

# Make script exit if a simple command fails and
# Make script print commands being executed
set -e -x

# Set names of latest versions of each package
version_tengine=tengine-2.3.0
source_tengine="http://tengine.taobao.org/download/"

# Make a "today" variable for use in back-up filenames later
today=$(date +"%Y-%m-%d")

# Clean out any files from previous runs of this script
cd /opt
rm -rf "$version_tengine"

# Ensure the required software to compile NGINX is installed
apt update && apt -y install \
  binutils \
  build-essential \
  libjemalloc-dev \
  libpcre3-dev \
  libssl-dev \
  zlib1g-dev \
  curl

wget "${source_tengine}${version_tengine}.tar.gz"

# Expand the source files
tar xzf "${version_tengine}.tar.gz"

# Clean up archive files
rm "${version_tengine}.tar.gz"

# Rename the existing /etc/nginx directory so it's saved as a back-up
if [ -d "/etc/nginx" ]; then
  mv /etc/nginx "/etc/nginx-${today}"
fi

# Create NGINX cache directories if they do not already exist
if [ ! -d "/var/cache/nginx/" ]; then
  mkdir -p \
    /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp
fi

# Add NGINX group and user if they do not already exist
id -g nginx &>/dev/null || addgroup --system nginx
id -u nginx &>/dev/null || adduser --disabled-password --system --home /var/cache/nginx --shell /sbin/nologin --group nginx

# Patch then configure NGINX with various modules included/excluded
cd "$version_tengine"
./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib/nginx/modules \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/var/run/nginx.pid \
  --lock-path=/var/run/nginx.lock \
  --http-client-body-temp-path=/var/cache/nginx/client_temp \
  --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
  --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
  --user=nginx \
  --group=nginx \
  --add-module=./modules/ngx_http_proxy_connect_module \
  --with-jemalloc \
  --without-http_empty_gif_module \
  --without-http_geo_module \
  --without-http_split_clients_module \
  --without-http_ssi_module \
  --without-mail_imap_module \
  --without-mail_pop3_module \
  --without-mail_smtp_module
make
make install
make clean
strip -s /usr/sbin/nginx*

# Install man pages
cp "man/nginx.8" /usr/share/man/man8
gzip -f /usr/share/man/man8/nginx.8

if [ -d "/etc/nginx-${today}" ]; then
  # Rename the default /etc/nginx settings directory so it's accessible as a reference to the new NGINX defaults
  mv /etc/nginx /etc/nginx-default

  # Restore the previous version of /etc/nginx to /etc/nginx so the old settings are kept
  mv "/etc/nginx-${today}" /etc/nginx
fi

# Create NGINX systemd service file if it does not already exist
if [ ! -e "/lib/systemd/system/nginx.service" ]; then
  # Control will enter here if the NGINX service doesn't exist.
  file="/lib/systemd/system/nginx.service"

  /bin/cat >$file <<'EOF'
[Unit]
Description=The NGINX reverse and forward proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable nginx
  systemctl start nginx
fi

echo "All done.";
