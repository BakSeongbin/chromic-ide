#!/bin/sh 

# 라이브러리 참조
#. /etc/rc.d/init.d/functions

#start 옵션 실행 시 메시지를 출력한다.
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

#status 옵션 실행 시 메시지를 출력한다.
  "status")
    echo ""
    iptables -L --line -nv
    echo ""

  exit;;

#stop 옵션 실행 시 메시지를 출력한다.
  "stop")
  echo "Stopping Firewall...:"
  echo ""
  iptables -F
  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT

  exit;;

# 아무런 옵션을 명시하지 않았을 경우 사용할 수 있는 옵션을 보여준다.
* )
    echo "You can use following command line args:"
    echo ""
    echo $BOLD"Usage: fw {start|stop|status}"
    echo ""

    exit;;
esac
