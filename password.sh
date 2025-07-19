set-password() {
echo "Changing admin account password"
kvmd-htpasswd set admin 
echo "Set password for admin account"
}

set-password