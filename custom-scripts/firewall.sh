#!/bin/sh

#----------------------------------------------------------
# ��ȭ�� ����
#----------------------------------------------------------

# ���� ������ ��� ����
ECHO="/bin/echo";

# ���̺귯�� ����
. /etc/rc.d/init.d/functions

#start �ɼ� ���� �� �޽����� ����Ѵ�.
case "$1" in
  "start")
    echo ""
    echo "Starting Firewall...:" echo
    echo ""
  ;;

#restart �ɼ� ���� �� �޽����� ����Ѵ�.
  "restart")
    action "Stopping down Firewall...:" echo
    iptables -F -t filter
    iptables -X -t filter
    iptables -F -t nat
    iptables -X -t nat
    iptables -F -t mangle
    iptables -X -t mangle
    iptables -P INPUT DROP 
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
  action "Starting Firewall...:" echo
  ;;
#status �ɼ� ���� �� �޽����� ����Ѵ�.
  "status")
    $ECHO
    iptables -L --line -nv
    $ECHO
  exit;;

#stop �ɼ� ���� �� �޽����� ����Ѵ�.
  "stop")
  action "Stopping Firewall...:" echo
  echo ""
  iptables -F -t filter
  iptables -X -t filter
  iptables -F -t nat
  iptables -X -t nat
  iptables -F -t mangle
  iptables -X -t mangle
  iptables -P INPUT ACCEPT
  iptables -P FORWARD DROP
  iptables -P OUTPUT ACCEPT
  exit
  ;;
# �ƹ��� �ɼ��� ������� �ʾ��� ��� ����� �� �ִ� �ɼ��� �����ش�.
* )
    $ECHO "You can use following command line args:"
    $ECHO
    $ECHO $BOLD"Usage: firewall {start|restart|stop|status}"
    $ECHO

    exit;;
esac

################################################################################
# Ŀ�� �Ķ���� ����
################################################################################
#-----------------------------------------------------------------------------------
# Servece kernel trait
#-------------------------------------------------
# TCP Syncookies �� ����Ҽ� �ְ� �ϱ� ����
  #echo 1 > /proc/sys/net/ipv4/tcp_syncookies

# ���ǵ��� ���� ���� �޽����� ����
  echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses


# ip �ּҸ� ��Ǫ���Ѵٰ� ����Ǵ� ��� �α׿� ����ϱ�
  echo 1 > /proc/sys/net/ipv4/conf/all/log_martians


# ��ε�ĳ��Ʈ, ��Ƽĳ��Ʈ �ּҿ� ICMP �޽��� �����°� ����, "smurf" ���� ����
  echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts

# packet forwarding �� �����ϰ� ��
  echo 1 > /proc/sys/net/ipv4/ip_forward
################################################################################
    
# rule, chain �ʱ�ȭ
iptables -F
iptables -X

# ����Ʈ ��å ����
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP
################################################################################
# ȯ�� ����
################################################################################
#Work_Dir=/var/log;                 # whitelist.txt, blacklist.txt ȭ�� ������
#File_Name_White=whitelist.txt;                # don't modify it !
#File_Name_Black=blacklist.txt;                # don't modify it !

#---------------------------------------------// source library function
# �ҽ� �Լ� ���̺귯���� ����
#----------------------------------
 source /etc/rc.d/init.d/functions
 source /etc/sysconfig/network
#------------------------------------

Host_Name=`hostname`;
#---------------------------------------------// ���� ���� ����
# �� ��ũ��Ʈ�� ���� ������ ����
#------------------------------------
Local_Ipaddr="`/sbin/ifconfig eth0 | grep 'inet addr' | awk '{print $2}' | /bin/sed -e 's/.*://'`"

############### ȯ�� ���� �� ###################################################

################################################################################
# ACCEPT ����
################################################################################

#������ Ʈ���� ���
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
# ���� IP ���
iptables -A INPUT -s $Local_Ipaddr -j ACCEPT
iptables -A OUTPUT -s $Local_Ipaddr -j ACCEPT

# �̹� ������ �ξ� �������� ���̺� ��Ͽ� �ִ� ESTABLISHED,RELATED ��Ŷ�� ���
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

################################################################################
# ���� ��� �� ����
################################################################################
# Accepted Port ����
# ���⿡�� Ư�� IP �뿪���� �����ϴ� ���񽺸� �����մϴ�.
# ������ �������� ssh ���� �����Ͻø� �˴ϴ�.

iptables -A INPUT -p TCP -s ip�ּ� --sport 1024: --dport ������ ��Ʈ -m state --state NEW -j ACCEPT

#UDP allowed port
ALLOWPORT_UDP="1024 1025 20000 137 138"  
for port in $ALLOWPORT_UDP;
do
  echo "Allowed UDP port $port..."
iptables -A INPUT -p UDP --sport 1024: --dport $port -m state --state NEW -j ACCEPT

done

sleep 5;
#TCP Allowed port
ALLOWPORT_TCP="80 3306 21 873 110 25"  
for port in $ALLOWPORT_TCP;
do
        echo "Allowed TCP port $port..."
iptables -A INPUT -p TCP --sport 1024: --dport $port -m state --state NEW -j ACCEPT
done

# �ܺο��� ������ traceroute ���
iptables -A INPUT -p udp --dport 33434:38000 -m state --state NEW -j ACCEPT

# icmp ��Ŷ �� echo-request ���
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
# icmp ��Ŷ �� echo-reply ���
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

# icmp ��Ŷ �� network-unreachable�� ���. ���񽺰źη� �ǿ�� �� �����Ƿ�
# limit�� �����Ͽ� �ʴ� 1ȸ���� ����Ѵ�.
iptables -A INPUT -p icmp --icmp-type network-unreachable -m limit --limit 1/s --limit-burst 5 -j ACCEPT

# icmp ��Ŷ �� host-unreachable�� ���. ���񽺰źη� �ǿ�� �� �����Ƿ�
# limit�� �����Ͽ� �ʴ� 1ȸ���� ����Ѵ�.
iptables -A INPUT -p icmp --icmp-type host-unreachable -m limit --limit 1/s --limit-burst 5 -j ACCEPT

# icmp ��Ŷ �� port-unreachable�� ���. ���񽺰źη� �ǿ�� �� �����Ƿ�
# limit�� �����Ͽ� �ʴ� 1ȸ���� ����Ѵ�.
iptables -A INPUT -p icmp --icmp-type port-unreachable -m limit --limit 1/s --limit-burst 5 -j ACCEPT

# icmp ��Ŷ �� fragmentation-needed�� ���. ���񽺰źη� �ǿ�� �� �����Ƿ�
# limit�� �����Ͽ� �ʴ� 1ȸ���� ����Ѵ�.
iptables -A INPUT -p icmp --icmp-type fragmentation-needed -m limit --limit 1/s --limit-burst 5 -j ACCEPT

# icmp ��Ŷ �� time-exceeded�� ���. ���񽺰źη� �ǿ�� �� �����Ƿ�
# limit�� �����Ͽ� �ʴ� 1ȸ���� ����Ѵ�.
iptables -A INPUT -p icmp --icmp-type time-exceeded -m limit --limit 1/s --limit-burst 5 -j ACCEPT

################################################################################
# ���� �ź� �� ����
################################################################################
#-----------------------------------------------------------------------------------
# ��Ǫ�ΰ� ���������� �ּ�
# ��Ǫ�ε� ��Ŷ�� �����Ѵ�. ���������� �ҽ� �ּҴ� DROP �Ѵ�.
# ������������ �߸��� �ּҸ� �ҽ��� �ؼ� ������ ��Ŷ�� �ź��Ѵ�.
# ��ġ �ҽ� �ּҰ� �ڽ��� IP �� ��ó�� �����ؼ� ������ ��Ŷ�� DROP �Ѵ�.

iptables -A INPUT -s ${Local_Ipaddr} -j DROP

# �缳 IP �� ����� �� �� ���� IP ���� INPUT Chain���� ����
iptables -A INPUT -s 10.0.0.0/8 -j DROP
iptables -A INPUT -s 255.255.255.255/32 -j DROP
iptables -A INPUT -s 0.0.0.0/8 -j DROP
iptables -A INPUT -s 169.254.0.0/16 -j DROP
iptables -A INPUT -s 172.16.0.0/12 -j DROP
iptables -A INPUT -s 192.0.2.0/24 -j DROP
iptables -A INPUT -s 192.168.0.0/16 -j DROP
iptables -A INPUT -s 224.0.0.0/4 -j DROP
iptables -A INPUT -s 240.0.0.0/5 -j DROP
iptables -A INPUT -s 248.0.0.0/5 -j DROP

#OUTPUT Chain���� ���͸� ����
iptables -A OUTPUT -s 10.0.0.0/8 -j DROP
iptables -A OUTPUT -s 255.255.255.255/32 -j DROP
iptables -A OUTPUT -s 0.0.0.0/8 -j DROP
iptables -A OUTPUT -s 169.254.0.0/16 -j DROP
iptables -A OUTPUT -s 172.16.0.0/12 -j DROP
iptables -A OUTPUT -s 192.0.2.0/24 -j DROP
iptables -A OUTPUT -s 192.168.0.0/16 -j DROP
iptables -A OUTPUT -s 224.0.0.0/4 -j DROP
iptables -A OUTPUT -s 240.0.0.0/5 -j DROP
iptables -A OUTPUT -s 248.0.0.0/5 -j DROP


# ��Ʈ ��ĵ�� ��� 1�п� 1���÷� �α׿� ���
#iptables -A INPUT -m psd -m limit --limit 1/minute -j LOG

# �α׿� ���� ���Ŀ��� ��Ʈ ��ĵ ��Ŷ�� ����
#iptables -A INPUT -m psd -j DROP

# ��ȭ���� ���� ������ tcp ��Ŷ �� �������� ���̺��� NEW�̸鼭 syn ��Ʈ�� ����
# �ʰ� ������ ��Ŷ�� �����Ѵ�. tcp ��Ŷ �� �������� ���̺� NEW��� �ݵ�� syn
# ��Ʈ�� ������ ��Ŷ�̾�� �� ���̸� �̿��� ��Ŷ�� ��� ������ ��Ŷ�̹Ƿ� �����Ѵ�.
iptables -A INPUT -p TCP ! --syn -m state --state NEW -j DROP

# �������� ���̺��� INVALID ��Ŷ ����
iptables -A INPUT -p ALL -m state --state INVALID -j DROP




# tcp-flags ����
# NMAP���� �̿��� FIN/URG/PSH ��ĵ�� �����ϱ� ���� ��� ��Ʈ�� ���캸��
# FIN,URG,PSH�� ������ ��Ŷ�� 1�п� 5�� ������ �α׿� ���� �� �����ϵ��� �Ѵ�.
# �α׸� ���� ���� �α� ������ �տ� "NMAP-XMAS:"�� �߰��ǵ��� �Ѵ�.

iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -m limit --limit 5/minute -j LOG --log-prefix "NMAP-XMAS:"
iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP

# SYN,FIN��Ʈ�� �Բ� ������ ��Ŷ�� �������̹Ƿ� �����Ѵ�.

iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP

# SYN,FIN ��Ʈ�� ���캸�� SYN,FIN��Ʈ�� �Բ� ������ ��Ŷ�� �����Ѵ�.

iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

# FIN,RST ��Ʈ�� ���캸�� FIN,RST��Ʈ�� �Բ� ������ ��Ŷ�� �����Ѵ�.

iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP

# ACK,FIN ��Ʈ�� ���캸�� ACK�� �������� �ʰ� FIN ��Ʈ�� ������ ��Ŷ�� �����Ѵ�.

iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN -j DROP

# ACK,PSH��Ʈ�� ���캸�� ACK�� �������� �ʰ� PSH ��Ʈ�� ������ ��Ŷ�� �����Ѵ�.

iptables -A INPUT -p tcp --tcp-flags ACK,PSH PSH -j DROP

# ACK,URG ��Ʈ�� ���캸�� ACK�� �������� �ʰ� URG ��Ʈ�� ������ ��Ŷ�� �����Ѵ�.

iptables -A INPUT -p tcp --tcp-flags ACK,URG URG -j DROP

# ��� ��Ʈ�� ���캸�� �ٸ� ��Ʈ�� �������� �ʰ� FIN ��Ʈ�� ������ ��Ŷ�� �����Ѵ�.

iptables -A INPUT -p tcp --tcp-flags ALL FIN -j DROP

# ��� ��Ʈ�� ���캸�� �ƹ��� ��Ʈ�� �������� ���� ��Ŷ�� �����Ѵ�.

iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# ��� ��Ʈ�� ���캸�� �ٸ� ��Ʈ�� �������� �ʰ� PSH,FIN ��Ʈ�� ������ ��Ŷ�� �����Ѵ�.

iptables -A INPUT -p tcp --tcp-flags ALL PSH,FIN -j DROP

# �α� ���� 
# drop �Ǵ� �Ϳ� ���Ͽ� �α׸� ����
# ���� �������� ��� ��� �Ϳ� ���Ͽ� �α׸� ����Ƿ� �׽��� �Ⱓ�� �������Ŀ��� �ּ�ó���ص���
# /var/log/messages �� �α������� ����
# ������ ���� ��쿡�� �α������� ����ġ�� Ŀ�� �� ����
# --log-prefix �κп��� �ڽ��� ���ϴ� ������ " "�ȿ� ������ �˴ϴ�. 
iptables -N RULE_DROP
iptables -A OUTPUT  -d $Local_Ipaddr  -j RULE_DROP
iptables -A INPUT  -d $Local_Ipaddr  -j RULE_DROP
iptables -A RULE_DROP  -j LOG  --log-level info --log-prefix "RULE_DROP -- DENY "
iptables -A RULE_DROP  -j DROP
