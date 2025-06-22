# 🛡️ PWM — A Minimalist FOSS Password Manager (macOS + Linux)

**PWM** is a terminal-based, SQLCipher-encrypted password manager written in Bash.
It prioritizes simplicity, full local control, and cross-platform compatibility — built to be clean, auditable, and usable offline on **macOS** and **Linux**.

---

## ✨ Features

* 🔐 **Full-disk & field-level encryption**

  * Entire DB secured with [SQLCipher](https://www.zetetic.net/sqlcipher/)
  * Passwords individually encrypted with AES-256-CBC using OpenSSL
* 🧹 **Keyfile-based unlock**, no master password prompt
* 💻 **macOS integration** via `osascript` (GUI dropdowns)
* 🐧 **Linux integration** via `dmenu`
* 🔄 **Cross-platform support** with config-based key paths
* ✍️ Optional **audit logging** and historical password tracking
* 🧰 Small codebase — easy to audit, modify, and extend

---

## 🧱 Requirements

### Common

* `bash`, `openssl`, `sqlcipher`

### Linux

* `dmenu`, `xclip`, `notify-send`, `veracrypt`

### macOS

* `osascript` (built-in)
* Encrypted `.dmg` image mounted via `hdiutil`
* Access to `security` CLI (for password retrieval from Keychain)
* `pbcopy` (for clipboard)

---

## 🚀 Setup

### 1. Clone this repo

```bash
git clone git@github.com:yourusername/pwm.git
cd pwm
```

### 2. Create your own `config.sh`

```bash
cp config.example.sh config.sh
```

Then edit `config.sh` to match your environment.

You'll define paths like:

```bash
# Path to encrypted SQLCipher database
DBFILE="pwm.db"

# macOS-only
DMG_PATH="/path/to/Encrypted.dmg"
MOUNT_POINT="/Volumes/YourVolume"
KEYFILE_SQLCIPHER_MAC="$MOUNT_POINT/key1"
KEYFILE_PASS_MAC="$MOUNT_POINT/key2"

# Linux-only
VERACRYPT_CONTAINER="/path/to/Encrypted.vc"
VERACRYPT_MOUNT="/media/yourvolume"
VC_KEYFILE="/path/to/keyfile"
KEYFILE_SQLCIPHER_LINUX="$VERACRYPT_MOUNT/key1"
KEYFILE_PASS_LINUX="$VERACRYPT_MOUNT/key2"
```

> 🔐 Your real `config.sh` should **never be committed**. It's ignored via `.gitignore`.

---

### 3. Generate encryption keyfiles

You’ll need:

* One keyfile for SQLCipher (`key1`)
* One keyfile for OpenSSL password encryption (`key2`)

You can use `/dev/urandom`:

```bash
head -c 64 /dev/urandom > key1
head -c 64 /dev/urandom > key2
```

Store these securely (inside your encrypted volume).

---

### 4. Create an encrypted volume

* **On Linux**: use [VeraCrypt](https://www.veracrypt.fr/en/Downloads.html)
* **On macOS**: use Disk Utility to create an encrypted `.dmg`

Inside that volume, place:

* `key1`
* `key2`

---

### 5. Create the SQLCipher database

You can initialize the database like this:

```bash
sqlcipher pwm.db <<EOF
PRAGMA key = 'your_key_here';
CREATE TABLE passwords (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  username TEXT NOT NULL,
  glit BLOB NOT NULL,
  url TEXT,
  notes TEXT,
  category TEXT,
  created DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE password_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  password_id INTEGER NOT NULL,
  old_password BLOB NOT NULL,
  changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (password_id) REFERENCES passwords (id) ON DELETE CASCADE
);
CREATE TABLE audit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  action TEXT NOT NULL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
EOF
```

Make sure to replace `'your_key_here'` with the output of `tr -d '\n' < key1`

---

### 6. First run

Make the script executable:

```bash
chmod +x pwm.sh
```

Run it:

```bash
./pwm.sh
```

* On macOS, GUI dropdowns prompt you to select a site and username
* On Linux, `dmenu` handles selection and clipboard access

---

## 🔁 Backups

Back up at least:

* Your encrypted database file (`pwm.db`)
* The two keyfiles (`key1`, `key2`)
* Optionally your encrypted container/disk image

Never store backups unencrypted.

---

## 📚 Structure

* `pwm.sh` — main script
* `config.example.sh` — safe template
* `.gitignore` — ignores secrets like `config.sh` and keys
* `pwm.db` — your encrypted SQLCipher database (not included)
* Encrypted volume — holds sensitive key material

---

## 🔓 Security Philosophy

* **No external servers or APIs** — fully offline
* **Field-level encryption** ensures secrets are unreadable even with DB access
* **Source is small and audit-friendly**
* **Key separation** — different keys for DB and field encryption

---

## 📦 Optional Enhancements

* Logging to the `audit_logs` table
* Password history rollback
* TOTP support (not yet implemented)
* Custom `dmenu` styles or `rofi` support
* GTK wrapper or cross-platform GUI frontend

---

## 🤝 Contributing

This project is open source under the GNU General Public License v2.0.
Feel free to fork, improve, and open PRs — but **do not include any real passwords, keys, or config files**.

---

## 🛠 License

[GNU GPL v2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

Built with security and simplicity in mind.

