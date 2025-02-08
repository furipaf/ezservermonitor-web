#!/bin/bash

# Exit on error
set -e

# Google Drive file ID (Extracted from the link you provided)
FILE_ID="1msoWbgJPNyUvLPoMZiq6sno9PKs4T9pw"
FILE_NAME="ezservermonitor-web-master.zip"
INSTALL_DIR="/var/www/html"

# Update and install required dependencies
echo "Updating system and installing dependencies..."
sudo apt update && sudo apt install -y python3-pip python3-venv unzip apache2 pipx

# Ensure pipx is set up properly
echo "Ensuring pipx is ready..."
pipx ensurepath
export PATH="${HOME}/.local/bin:$PATH"

# Install gdown using pipx if not already installed
if ! command -v gdown &> /dev/null; then
    echo "Installing gdown using pipx..."
    pipx install gdown
fi

# Change permissions of /var/www/html directories to 777
echo "Setting permissions of $INSTALL_DIR directories to 777..."
sudo find "$INSTALL_DIR" -type d -exec chmod 777 {} +

# Download the file from Google Drive
echo "Downloading file from Google Drive..."
gdown --id "$FILE_ID" -O "$FILE_NAME"

# Extract the zip file
echo "Extracting $FILE_NAME to $INSTALL_DIR..."
unzip -o "$FILE_NAME" -d "$INSTALL_DIR"

# Verify extracted file structure
echo "Verifying extracted files..."
ls -R "$INSTALL_DIR"

# Restore permissions and set ownership
echo "Restoring permissions and setting ownership for $INSTALL_DIR..."
sudo chown -R www-data:www-data "$INSTALL_DIR"
sudo chmod -R 755 "$INSTALL_DIR"

# Create Apache configuration file
echo "Creating Apache configuration for eSM..."
CONFIG_FILE="/etc/apache2/sites-available/esm.conf"
echo "<VirtualHost *:80>
    DocumentRoot $INSTALL_DIR
    <Directory $INSTALL_DIR>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" | sudo tee "$CONFIG_FILE"

# Enable the new site and disable the default site
echo "Enabling eSM site and disabling default site..."
sudo a2ensite esm.conf
sudo a2dissite 000-default.conf
sudo systemctl reload apache2

# Display configuration file location
echo "To customize settings, edit: $INSTALL_DIR/conf/esm.config.json"

# Cleanup (optional)
echo "Cleaning up..."
rm "$FILE_NAME"

echo "Installation complete! You can now access the application at: http://<your-raspberry-pi-ip>/"
