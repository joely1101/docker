
# Check if running in privileged mode
if [ ! -w "/sys" ] ; then
    echo "[Error] Not running in privileged mode."
fi

hostapd_main() {
    # Default values
    true ${INTERFACE:=eth0}
    true ${IP_ADDR:=192.168.1.200}
    # Generate config file for hostapd
    mkdir -p "/etc/hostapd"
    if [ ! -f "/etc/hostapd/hostapd.conf" ] ; then
        cat > "/etc/hostapd/hostapd.conf" <<EOF
interface=${INTERFACE}
driver=wired
logger_syslog=-1
logger_syslog_level=2
logger_stdout=-1
logger_stdout_level=2
dump_file=/tmp/hostapd.dump
ctrl_interface=/var/run/hostapd
ieee8021x=1
eapol_key_index_workaround=0
eap_server=1
eap_user_file=/etc/hostapd/hostapd.eap_user
EOF
    fi

    if [ ! -f "/etc/hostapd/hostapd.eap_user" ] ; then
        cat > "/etc/hostapd/hostapd.eap_user" <<EOF
# Phase 1 users
"peap"	PEAP
"md5"	MD5	"md5"


# Phase 2
"peap"	MD5	"peap"	[2]
EOF

    fi

    # Setup interface and restart DHCP service 
    ip link set ${INTERFACE} up
    ip addr flush dev ${INTERFACE}
    ip addr add ${IP_ADDR}/24 dev ${INTERFACE}
}

# Check environment variables
rm /etc/hostapd/hostapd.eap_user /etc/hostapd/hostapd.conf
hostapd_main
/usr/sbin/hostapd -dd /etc/hostapd/hostapd.conf
