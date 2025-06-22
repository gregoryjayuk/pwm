#!/bin/bash
set -e
source "$(dirname "$0")/config.sh"

if [[ -e ~/.config/apple ]]; then
    cd "$MAC_SRC_DIR"

    # Mount encrypted volume using password from keychain
    PPP=$(security find-generic-password -a "$USER" -s "PwM" -w 2>&1 | tail -n 1)
    printf "%s" "$PPP" | hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_POINT" -nobrowse -stdinpass

    if [ $? -ne 0 ]; then
        osascript -e 'display notification "Failed to mount encrypted volume." with title "PWM"'
        exit 1
    fi

    KEYONE="$KEYFILE_SQLCIPHER_MAC"
    KEYTWO="$KEYFILE_PASS_MAC"
else
    sudo veracrypt -t --non-interactive -k="$VC_KEYFILE" "$VERACRYPT_CONTAINER" "$VERACRYPT_MOUNT"
    cd "$LINUX_SRC_DIR"
    KEYONE="$KEYFILE_SQLCIPHER_LINUX"
    KEYTWO="$KEYFILE_PASS_LINUX"
fi

SQLCIPHER_KEY=$(tr -d '\n' < "$KEYONE")
RESULT=$(sqlcipher "$DBFILE" <<EOF
PRAGMA key = '$SQLCIPHER_KEY';
SELECT DISTINCT name FROM passwords ORDER BY name COLLATE NOCASE;
EOF
)

if [[ -e ~/.config/apple ]]; then
    APPLE_LIST=$(echo "$RESULT" | grep -v '^ok$' | awk 'BEGIN{ORS=", "}{print "\"" \$0 "\""}' | sed 's/, $//')
    SITECHOICE=$(osascript -e "choose from list {$APPLE_LIST} with prompt \"Select a site:\"")

    if [ "$SITECHOICE" = "false" ]; then
        echo "No selection made."
        exit 1
    fi

    USER_RESULT=$(sqlcipher "$DBFILE" <<EOF
PRAGMA key = '$SQLCIPHER_KEY';
SELECT username FROM passwords WHERE name = '$SITECHOICE';
EOF
)
    USER_APPLE_LIST=$(echo "$USER_RESULT" | grep -v '^ok$' | awk 'BEGIN{ORS=", "}{print "\"" \$0 "\""}' | sed 's/, $//')
    USERCHOICE=$(osascript -e "choose from list {$USER_APPLE_LIST} with prompt \"Select Username:\"")

    if [ "$USERCHOICE" = "false" ]; then
        echo "No selection made."
        exit 1
    fi

    A_PASS_RESULT=$(sqlcipher "$DBFILE" <<EOF
PRAGMA key = '$SQLCIPHER_KEY';
SELECT glit FROM passwords WHERE name = '$SITECHOICE' AND username = '$USERCHOICE';
EOF
)
    AGETGLIT=$(echo "$A_PASS_RESULT" | grep -v '^ok$' | tr -d '\r' | sed 's/^\s*//;s/\s*$//')
    ADECRYPTED_PASSWORD=$(printf "%s\n" "$AGETGLIT" | openssl enc -d -aes-256-cbc -base64 -pass file:"$KEYTWO" -pbkdf2)

    echo "$ADECRYPTED_PASSWORD" | pbcopy
    hdiutil detach "$MOUNT_POINT" -quiet
    exit 0

else
    echo "notAPPLE"
    GETSITE=$(echo "$RESULT" | grep -v '^ok$' | tr -d '\r' | sed 's/^\s*//;s/\s*$//' | dmenu -z 600 -l 20)

    if [[ $GETSITE == "add" ]]; then
        SITE=$(echo "" | dmenu -z 600 -p "Site Name:")
        [[ -z "$SITE" ]] && { notify-send "No Site entered, exited"; exit 0; }

        URL=$(echo "" | dmenu -z 600 -p "URL:")
        USER=$(echo "" | dmenu -z 600 -p "Username:")
        RAWPASS=$(echo "" | dmenu -z 600 -p "Password:")
        COMMENTS=$(echo "" | dmenu -z 600 -p "Comments:")

        SQLCIPHER_KEY=$(tr -d '\n' < "$KEYONE")
        ENCPASS=$(printf "%s\n" "$RAWPASS" | openssl enc -aes-256-cbc -base64 -pass file:"$KEYTWO" -pbkdf2)

        esc() { printf '%s' "$1" | sed "s/'/''/g"; }
        SITE_E=$(esc "$SITE")
        URL_E=$(esc "$URL")
        USER_E=$(esc "$USER")
        NOTE_E=$(esc "$COMMENTS")
        PASS_E=$(esc "$ENCPASS")

        sqlcipher "$DBFILE" <<EOF
PRAGMA key = '$SQLCIPHER_KEY';
INSERT INTO passwords (name, username, glit, url, notes, category) VALUES ('$SITE_E', '$USER_E', '$PASS_E', '$URL_E', '$NOTE_E', '');
EOF

        notify-send "Password Saved"
        cd ~/
        sudo veracrypt -d "$VERACRYPT_CONTAINER"
        exit 0

    elif [[ $GETSITE == "del" ]]; then
        esc() { printf '%s' "$1" | sed "s/'/''/g"; }
        SQLCIPHER_KEY=$(tr -d '\n' < "$KEYONE")

        SITES=$(sqlcipher -cmd "PRAGMA key = '$SQLCIPHER_KEY';" "$DBFILE" "SELECT DISTINCT name FROM passwords ORDER BY name COLLATE NOCASE;")
        DELSITE=$(echo "$SITES" | grep -v '^ok$' | dmenu -z 600 -l 20 -p "Select Site")
        [[ -z "$DELSITE" ]] && { notify-send "No site selected"; exit 0; }

        USERLIST=$(sqlcipher -cmd "PRAGMA key = '$SQLCIPHER_KEY';" "$DBFILE" "SELECT username FROM passwords WHERE name='$(esc "$DELSITE")' ORDER BY username COLLATE NOCASE;")
        DELUSER=$(echo "$USERLIST" | grep -v '^ok$' | dmenu -z 600 -l 20 -p "Select Username to delete")
        [[ -z "$DELUSER" ]] && { notify-send "No user selected"; exit 0; }

        DELCONF=$(echo "" | dmenu -z 600 -p "Delete $DELSITE — $DELUSER? (y/n)")
        if [[ "$DELCONF" == "y" ]]; then
            sqlcipher "$DBFILE" <<EOF
PRAGMA key = '$SQLCIPHER_KEY';
DELETE FROM passwords WHERE name = '$(esc "$DELSITE")' AND username = '$(esc "$DELUSER")';
EOF
            notify-send "Deleted $DELSITE — $DELUSER"
            cd ~/
            sudo veracrypt -d "$VERACRYPT_CONTAINER"
            exit 0
        else
            notify-send "Delete canceled"
        fi
    fi

    USER_RESULT=$(sqlcipher "$DBFILE" <<EOF
PRAGMA key = '$SQLCIPHER_KEY';
SELECT username FROM passwords WHERE name = '$GETSITE';
EOF
)
    GETUSER=$(echo "$USER_RESULT" | grep -v '^ok$' | tr -d '\r' | sed 's/^\s*//;s/\s*$//' | dmenu -z 600 -l 20)

    PASS_RESULT=$(sqlcipher "$DBFILE" <<EOF
PRAGMA key = '$SQLCIPHER_KEY';
SELECT glit FROM passwords WHERE name = '$GETSITE' AND username = '$GETUSER';
EOF
)
    GETGLIT=$(echo "$PASS_RESULT" | grep -v '^ok$' | tr -d '\r' | sed 's/^\s*//;s/\s*$//')
    DECRYPTED_PASSWORD=$(printf "%s\n" "$GETGLIT" | openssl enc -d -aes-256-cbc -base64 -pass file:"$KEYTWO" -pbkdf2)

    echo "$DECRYPTED_PASSWORD" | xclip -selection c
fi

cd ~/
sudo veracrypt -d "$VERACRYPT_CONTAINER"

