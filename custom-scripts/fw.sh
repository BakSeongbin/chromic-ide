#!/bin/sh 

# ���̺귯�� ����
#. /etc/rc.d/init.d/functions

#start �ɼ� ���� �� �޽����� ����Ѵ�.
case "$1" in
  "start")
    echo ""
    echo "Starting Firewall...:" 
    echo ""
    iptables -F
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -m state --state INVALID -j LOG --log-prefix "---DROP INVALID INPUT---" --log-level 7 --log-ip-options --log-tcp-options --log-tcp-sequence

  exit;;

#status �ɼ� ���� �� �޽����� ����Ѵ�.
  "status")
    echo ""
    iptables -L --line -nv
    echo ""

  exit;;

#stop �ɼ� ���� �� �޽����� ����Ѵ�.
  "stop")
  echo "Stopping Firewall...:"
  echo ""
  iptables -F
  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT

  exit;;

# �ƹ��� �ɼ��� ������� �ʾ��� ��� ����� �� �ִ� �ɼ��� �����ش�.
* )
    echo "You can use following command line args:"
    echo ""
    echo $BOLD"Usage: fw {start|stop|status}"
    echo ""

    exit;;
esac
