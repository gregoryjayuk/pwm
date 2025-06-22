# config.example.sh
# Copy this to config.sh and fill in paths for your system

# Path to your SQLCipher-encrypted database
DBFILE="your_database_filename.docx"

# macOS Settings
MAC_SRC_DIR="/path/to/your/project"
DMG_PATH="/path/to/encrypted.dmg"
MOUNT_POINT="/Volumes/YourMountPoint"
KEYFILE_SQLCIPHER_MAC="$MOUNT_POINT/keyfile1"
KEYFILE_PASS_MAC="$MOUNT_POINT/keyfile2"

# Linux Settings
LINUX_SRC_DIR="/path/to/your/project"
VERACRYPT_CONTAINER="/path/to/encrypted_container"
VERACRYPT_MOUNT="/mount/point"
KEYFILE_SQLCIPHER_LINUX="$VERACRYPT_MOUNT/keyfile1"
KEYFILE_PASS_LINUX="$VERACRYPT_MOUNT/keyfile2"

# Optional: VeraCrypt keyfile (for mounting encrypted volume on Linux)
VC_KEYFILE="/path/to/your/veracrypt/keyfile"

