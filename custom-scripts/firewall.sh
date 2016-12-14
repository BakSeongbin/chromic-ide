#!/bin/sh

#----------------------------------------------------------
# 방화벽 시작
#----------------------------------------------------------

# 실행 파일의 경로 지정
ECHO="/bin/echo";

# 라이브러리 참조
. /etc/rc.d/init.d/functions

#start 옵션 실행 시 메시지를 출력한다.
case "$1" in
  "start")
    echo ""
    echo "Starting Firewall...:" echo
    echo ""
  ;;

#restart 옵션 실행 시 메시지를 출력한다.
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
#status 옵션 실행 시 메시지를 출력한다.
  "status")
    $ECHO
    iptables -L --line -nv
    $ECHO
  exit;;

#stop 옵션 실행 시 메시지를 출력한다.
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
# 아무런 옵션을 명시하지 않았을 경우 사용할 수 있는 옵션을 보여준다.
* )
    $ECHO "You can use following command line args:"
    $ECHO
    $ECHO $BOLD"Usage: firewall {start|restart|stop|status}"
    $ECHO

    exit;;
esac

################################################################################
# 커널 파라미터 설정
################################################################################
#-----------------------------------------------------------------------------------
# Servece kernel trait
#-------------------------------------------------
# TCP Syncookies 를 사용할수 있게 하기 위해
  #echo 1 > /proc/sys/net/ipv4/tcp_syncookies

# 정의되지 않은 에러 메시지를 막음
  echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses


# ip 주소를 스푸핑한다고 예상되는 경우 로그에 기록하기
  echo 1 > /proc/sys/net/ipv4/conf/all/log_martians


# 브로드캐스트, 멀티캐스트 주소에 ICMP 메시지 보내는것 막기, "smurf" 공격 방지
  echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts

# packet forwarding 을 가능하게 함
  echo 1 > /proc/sys/net/ipv4/ip_forward
################################################################################
    
# rule, chain 초기화
iptables -F
iptables -X

# 디폴트 정책 설정
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP
################################################################################
# 환경 설정
################################################################################
#Work_Dir=/var/log;                 # whitelist.txt, blacklist.txt 화일 넣을곳
#File_Name_White=whitelist.txt;                # don't modify it !
#File_Name_Black=blacklist.txt;                # don't modify it !

#---------------------------------------------// source library function
# 소스 함수 라이브러리를 참고
#----------------------------------
 source /etc/rc.d/init.d/functions
 source /etc/sysconfig/network
#------------------------------------

Host_Name=`hostname`;
#---------------------------------------------// 공통 변수 선언
# 본 스크립트에 사용될 변수들 선언
#------------------------------------
Local_Ipaddr="`/sbin/ifconfig eth0 | grep 'inet addr' | awk '{print $2}' | /bin/sed -e 's/.*://'`"

############### 환경 설정 끝 ###################################################

################################################################################
# ACCEPT 설정
################################################################################

#루프백 트래픽 허용
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
# 로컬 IP 허용
iptables -A INPUT -s $Local_Ipaddr -j ACCEPT
iptables -A OUTPUT -s $Local_Ipaddr -j ACCEPT

# 이미 세션을 맺어 상태추적 테이블 목록에 있는 ESTABLISHED,RELATED 패킷은 허용
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

################################################################################
# 서비스 허용 룰 설정
################################################################################
# Accepted Port 설정
# 여기에는 특정 IP 대역에서 접속하는 서비스를 설정합니다.
# 관리자 페이지나 ssh 등을 설정하시면 됩니다.

iptables -A INPUT -p TCP -s ip주소 --sport 1024: --dport 접속할 포트 -m state --state NEW -j ACCEPT

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

# 외부에서 서버로 traceroute 허용
iptables -A INPUT -p udp --dport 33434:38000 -m state --state NEW -j ACCEPT

# icmp 패킷 중 echo-request 허용
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
# icmp 패킷 중 echo-reply 허용
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

# icmp 패킷 중 network-unreachable을 허용. 서비스거부로 악용될 수 있으므로
# limit를 지정하여 초당 1회씩만 허용한다.
iptables -A INPUT -p icmp --icmp-type network-unreachable -m limit --limit 1/s --limit-burst 5 -j ACCEPT

# icmp 패킷 중 host-unreachable을 허용. 서비스거부로 악용될 수 있으므로
# limit를 지정하여 초당 1회씩만 허용한다.
iptables -A INPUT -p icmp --icmp-type host-unreachable -m limit --limit 1/s --limit-burst 5 -j ACCEPT

# icmp 패킷 중 port-unreachable을 허용. 서비스거부로 악용될 수 있으므로
# limit를 지정하여 초당 1회씩만 허용한다.
iptables -A INPUT -p icmp --icmp-type port-unreachable -m limit --limit 1/s --limit-burst 5 -j ACCEPT

# icmp 패킷 중 fragmentation-needed을 허용. 서비스거부로 악용될 수 있으므로
# limit를 지정하여 초당 1회씩만 허용한다.
iptables -A INPUT -p icmp --icmp-type fragmentation-needed -m limit --limit 1/s --limit-burst 5 -j ACCEPT

# icmp 패킷 중 time-exceeded을 허용. 서비스거부로 악용될 수 있으므로
# limit를 지정하여 초당 1회씩만 허용한다.
iptables -A INPUT -p icmp --icmp-type time-exceeded -m limit --limit 1/s --limit-burst 5 -j ACCEPT

################################################################################
# 서비스 거부 룰 설정
################################################################################
#-----------------------------------------------------------------------------------
# 스푸핑과 비정상적인 주소
# 스푸핑된 패킷을 차단한다. 비정상적인 소스 주소는 DROP 한다.
# 서버에서부터 잘못된 주소를 소스로 해서 나가는 패킷을 거부한다.
# 마치 소스 주소가 자신의 IP 인 것처럼 위장해서 들어오는 패킷을 DROP 한다.

iptables -A INPUT -s ${Local_Ipaddr} -j DROP

# 사설 IP 및 라우팅 될 수 없는 IP 차단 INPUT Chain에서 설정
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

#OUTPUT Chain에서 필터링 설정
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


# 포트 스캔의 경우 1분에 1개꼴로 로그에 기록
#iptables -A INPUT -m psd -m limit --limit 1/minute -j LOG

# 로그에 남긴 이후에는 포트 스캔 패킷을 차단
#iptables -A INPUT -m psd -j DROP

# 방화벽을 향해 들어오는 tcp 패킷 중 상태추적 테이블에는 NEW이면서 syn 비트를 달지
# 않고 들어오는 패킷은 차단한다. tcp 패킷 중 상태추적 테이블에 NEW라면 반드시 syn
# 비트가 설정된 패킷이어야 할 것이며 이외의 패킷은 모두 위조된 패킷이므로 차단한다.
iptables -A INPUT -p TCP ! --syn -m state --state NEW -j DROP

# 상태추적 테이블에서 INVALID 패킷 차단
iptables -A INPUT -p ALL -m state --state INVALID -j DROP




# tcp-flags 설정
# NMAP등을 이용한 FIN/URG/PSH 스캔을 차단하기 위해 모든 비트를 살펴보아
# FIN,URG,PSH가 설정된 패킷은 1분에 5개 비율로 로그에 남긴 후 차단하도록 한다.
# 로그를 남길 때는 로그 정보의 앞에 "NMAP-XMAS:"가 추가되도록 한다.

iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -m limit --limit 5/minute -j LOG --log-prefix "NMAP-XMAS:"
iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP

# SYN,FIN비트가 함께 설정된 패킷은 비정상이므로 차단한다.

iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP

# SYN,FIN 비트를 살펴보아 SYN,FIN비트가 함께 설정된 패킷은 차단한다.

iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

# FIN,RST 비트를 살펴보아 FIN,RST비트가 함께 설정된 패킷은 차단한다.

iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP

# ACK,FIN 비트를 살펴보아 ACK는 설정되지 않고 FIN 비트만 설정된 패킷은 차단한다.

iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN -j DROP

# ACK,PSH비트를 살펴보아 ACK는 설정되지 않고 PSH 비트만 설정된 패킷은 차단한다.

iptables -A INPUT -p tcp --tcp-flags ACK,PSH PSH -j DROP

# ACK,URG 비트를 살펴보아 ACK는 설정되지 않고 URG 비트만 설정된 패킷은 차단한다.

iptables -A INPUT -p tcp --tcp-flags ACK,URG URG -j DROP

# 모든 비트를 살펴보아 다른 비트는 설정되지 않고 FIN 비트만 설정된 패킷은 차단한다.

iptables -A INPUT -p tcp --tcp-flags ALL FIN -j DROP

# 모든 비트를 살펴보아 아무런 비트도 설정되지 않은 패킷은 차단한다.

iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# 모든 비트를 살펴보아 다른 비트는 설정되지 않고 PSH,FIN 비트만 설정된 패킷은 차단한다.

iptables -A INPUT -p tcp --tcp-flags ALL PSH,FIN -j DROP

# 로그 설정 
# drop 되는 것에 대하여 로그를 남김
# 위의 설정에서 벗어난 모든 것에 대하여 로그를 남기므로 테스팅 기간을 지난이후에는 주석처리해도됨
# /var/log/messages 에 로그파일이 남음
# 접속이 많은 경우에는 로그파일이 지나치게 커질 수 있음
# --log-prefix 부분에는 자신이 원하는 문구를 " "안에 넣으면 됩니다. 
iptables -N RULE_DROP
iptables -A OUTPUT  -d $Local_Ipaddr  -j RULE_DROP
iptables -A INPUT  -d $Local_Ipaddr  -j RULE_DROP
iptables -A RULE_DROP  -j LOG  --log-level info --log-prefix "RULE_DROP -- DENY "
iptables -A RULE_DROP  -j DROP
