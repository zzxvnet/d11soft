#!/bin/bash

# 定义ANSI颜色代码
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
RESET='\e[0m'


# 设置定时重启任务
schedule_reboot() {
  printf "${YELLOW}请选择定时重启任务的类型：\n"
  printf "1. 每天早上5点重启系统\n"
  printf "2. 自定义重启时间${RESET}\n"
  read -p "请输入选择的序号： " reboot_choice

  case $reboot_choice in
    1)
      printf "${GREEN}正在设置标准定时重启任务...\n"
      # 创建标准的每天早上5点重启的定时任务
      echo "0 5 * * * root /sbin/reboot" | sudo tee /etc/cron.d/my_custom_reboot_job
      printf "标准定时重启任务已设置，每天早上5点将进行系统重启。${RESET}\n"
      ;;
    2)
      printf "${GREEN}请输入自定义的定时重启时间，例如：每天下午3点重启系统，输入：15 15\n"
      read -p "请输入定时任务的时间设置： " custom_time
      # 创建自定义时间的定时任务
      echo "$custom_time * * * root /sbin/reboot" | sudo tee /etc/cron.d/my_custom_reboot_job
      printf "自定义定时重启任务已设置，每天 $custom_time 将进行系统重启。${RESET}\n"
      ;;
    *)
      printf "${RED}无效选择，请重新输入。${RESET}\n"
      ;;
  esac

  # 显示当前的定时任务列表
  printf "${BLUE}当前定时任务列表：\n"
  sudo cat /etc/cron.d/my_custom_reboot_job
  printf "${RESET}\n"
}

# 检查并安装缺失的软件包
install_package() {
  package=$1
  if ! dpkg -l | grep -q "^ii.*$package"; then
    echo "正在安装 $package ..."
    sudo apt-get update
    sudo apt-get install -y "$package"
  else
    echo "$package 已经安装。"
  fi
}

# 安装网络工具和BBR
install_network_tools_and_bbr() {
  # 在安装其他工具之前安装 curl 和 wget
  for package in curl wget; do
    install_package "$package"
  done

  # 安装 bbr
  install_bbr() {
    if ! lsmod | grep -q "tcp_bbr"; then
      echo "正在启用 bbr ..."
      sudo bash -c 'echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf'
      sudo bash -c 'echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf'
      sudo sysctl -p
    else
      echo "bbr 已经启用。"
    fi
  }

  # 检查 ifconfig
  if ! command -v ifconfig &>/dev/null; then
    install_package net-tools
  else
    echo "ifconfig 已经安装。"
  fi

  # 检查并安装其他软件包
  for package in iperf3 mtr; do
    install_package "$package"
  done

  # 安装 bbr
  install_bbr
}

# 安装 Docker
install_docker() {
  echo "正在下载 Docker 安装脚本..."
  wget -q -O docker_installation.sh https://gitee.com/SuperManito/LinuxMirrors/raw/main/DockerInstallation.sh
  echo "下载完成。"

  # 询问用户是否要安装 Docker
  while true; do
    read -p "是否要安装 Docker？[Y/n] " yn
    case $yn in
      [Yy]* ) 
        echo "正在安装 Docker..."
        bash docker_installation.sh
        break
        ;;
      [Nn]* ) 
        echo "跳过安装 Docker。"
        break
        ;;
      * )
        echo "请输入 Y (yes) 或者 N (no)。"
        ;;
    esac
  done
}

# 一键安装 XrayR
install_xrayr() {
  echo "正在下载 XrayR 安装脚本..."
  wget -q -O xrayr_install.sh https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh
  echo "下载完成。"

  read -p "您是否要立即安装 XrayR？(y/n): " install_choice
  if [[ $install_choice =~ ^[Yy]$ ]]; then
    echo "正在安装 XrayR..."
    bash xrayr_install.sh
  else
    echo "如需稍后安装 XrayR，请运行以下命令："
    echo "  bash xrayr_install.sh"
  fi
}

# 获取默认网关接口
gateway_interface=$(ip route | awk '/default/ { print $5 }')

# 第四个菜单选项
install_iptables() {
  # 检查是否已安装iptables
  if ! command -v iptables &>/dev/null; then
    echo -e "${YELLOW}正在安装 iptables ..."
    sudo apt-get update
    sudo apt-get install -y iptables
  fi

  enable_ip_forward  # 启用IP转发

  echo -e "${GREEN}开始设置iptables规则...\n"

  read -p "请输入要转发的目标IP地址： " target_ip
  read -p "请选择转发方式：\n  1. 端口到端口\n  2. Web端口转发\n  3. 全端口转发\n请选择[1/2/3]: " forward_choice

  case $forward_choice in
    1)
      read -p "请输入源端口： " source_port
      read -p "请输入目标端口： " target_port
      # 端口到端口转发规则
      sudo iptables -t nat -A PREROUTING -p tcp -i "$gateway_interface" --dport $source_port -j DNAT --to-destination $target_ip:$target_port
      ;;
    2)
      # Web端口转发规则
      sudo iptables -t nat -A PREROUTING -p tcp -i "$gateway_interface" --dport 80 -j DNAT --to-destination $target_ip:8080
      sudo iptables -t nat -A PREROUTING -p tcp -i "$gateway_interface" --dport 443 -j DNAT --to-destination $target_ip:8443
      ;;
    3)
      # 全端口转发规则
      sudo iptables -t nat -A PREROUTING -p tcp -i "$gateway_interface" --sport 1:65535 -j DNAT --to-destination $target_ip:B
      ;;
    *)
      echo -e "${RED}无效选择，请重新输入。${RESET}"
      ;;
  esac

  echo -e "${RESET}\niptables规则设置完成。\n"
}


# 启用IP转发
enable_ip_forward() {
  echo -e "${GREEN}启用IP转发...\n"
  
  # 检查是否已启用IP转发
  if ! grep -qxF 'net.ipv4.ip_forward=1' /etc/sysctl.conf; then
    echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
  else
    echo "IP转发已经启用。"
  fi

  # 应用更改
  sudo sysctl -p

  echo -e "${RESET}\nIP转发已启用。\n"
}



# Speedtest 测试
install_speedtest() {
  if ! command -v speedtest &>/dev/null; then
    echo "正在安装 Speedtest ..."
    sudo apt-get install -y curl
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
    sudo apt-get install -y speedtest
  else
    echo "Speedtest 已经安装。"
  fi

  echo "正在进行 Speedtest 测试 ..."
  speedtest
}

# 关闭 IPv6
disable_ipv6() {
  echo "正在关闭 IPv6 ..."

  # 在 sysctl.conf 中禁用 IPv6
  echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
  echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf

  # 在所有网络接口上禁用 IPv6
  for interface in $(ls /sys/class/net/ | grep -v lo); do
    echo "正在在 $interface 上禁用 IPv6"
    echo "net.ipv6.conf.$interface.disable_ipv6 = 1" >> /etc/sysctl.conf
  done

  # 应用 sysctl 设置
  sysctl -p

  # 在网络接口配置文件中禁用 IPv6
  for interface_file in $(ls /etc/network/interfaces.d/); do
    echo "iface $(basename -s .cfg $interface_file) inet6 manual" >> /etc/network/interfaces.d/$interface_file
  done

  # 重启网络服务
  systemctl restart networking

  echo "IPv6 已被禁用"
}

# 安装性能测试工具wrk
install_wrk() {
  if ! command -v wrk &>/dev/null; then
    echo "正在安装 wrk ..."
    sudo apt-get install -y wrk
  else
    echo "wrk 已经安装。"
  fi
}

# 运行wrk性能测试
run_wrk_test() {
  read -p "${GREEN}请输入要测试的网址：${RESET} " url
  wrk -c 100 -t 10 "$url"
  echo -e "${GREEN}性能测试已完成。${RESET}"
  read -p "按 Enter 返回主菜单。"
}

# 修改DNS设置和设置文件保护属性
modify_dns() {
  if [[ -f /etc/resolv.conf && $(lsattr -d /etc/resolv.conf | cut -c5) == "i" ]]; then
    read -p "当前DNS已设置为不可更改。是否需要解锁文件进行修改？[Y/n] " unlock_choice
    if [[ $unlock_choice =~ ^[Yy]$ ]]; then
      sudo chattr -i /etc/resolv.conf
      echo "文件已解锁，可以进行修改。"
    else
      echo "取消修改DNS。"
      return
    fi
  fi
  
  read -p "请输入要设置的 DNS 地址： " dns_address
  echo "nameserver $dns_address" | sudo tee /etc/resolv.conf >/dev/null
  sudo chattr +i /etc/resolv.conf
  echo "DNS已修改为 $dns_address 并且设置为不可更改。"

  # 执行 nslookup 命令以验证 DNS 修改
  echo "正在执行 nslookup youtube.com："
  nslookup youtube.com
}


# 流媒体解锁功能
streaming_unlock() {
  echo -e "${YELLOW}请选择流媒体解锁命令："
  echo -e "1. bash <(curl -L -s check.unlock.media)"
  echo -e "2. bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh)${RESET}"
  read -p "请输入选择的序号： " streaming_choice

  case $streaming_choice in
    1)
      echo "正在执行流媒体解锁命令 1："
      bash <(curl -L -s check.unlock.media)
      ;;
    2)
      echo "正在执行流媒体解锁命令 2："
      bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh)
      ;;
    *)
      echo -e "${RED}无效选择，请重新输入。${RESET}"
      ;;
  esac
}
# tcptraceroute
use_tcptraceroute() {
  # 检查是否已安装 tcptraceroute
  if ! command -v tcptraceroute &>/dev/null; then
    echo "正在安装 tcptraceroute ..."
    sudo apt-get update
    sudo apt-get install -y tcptraceroute
  fi

  # 提示用户输入测试IP和端口
  read -p "请输入要测试的目标IP地址： " target_ip
  read -p "请输入要测试的端口号： " target_port

  # 使用 tcptraceroute 进行测试
  echo "正在使用 tcptraceroute 进行测试..."
  tcptraceroute $target_ip $target_port
}
# 新功能函数
use_iperf3() {
  # 检查是否已安装 iperf3
  if ! command -v iperf3 &>/dev/null; then
    echo "正在安装 iperf3 ..."
    sudo apt-get update
    sudo apt-get install -y iperf3
  fi

  read -p "您想作为服务端还是客户端？[S/C]: " iperf_choice

  if [[ $iperf_choice == "S" || $iperf_choice == "s" ]]; then
    echo "作为服务端运行 iperf3 ..."
    iperf3 -s
  elif [[ $iperf_choice == "C" || $iperf_choice == "c" ]]; then
    read -p "请输入目标 IP 地址： " target_ip
    read -p "您是否想要进行反向测试？[Y/n]: " reverse_choice

    if [[ $reverse_choice == "Y" || $reverse_choice == "y" ]]; then
      echo "作为客户端连接至 $target_ip 并进行反向测试..."
      iperf3 -c $target_ip -R
    else
      echo "作为客户端连接至 $target_ip..."
      iperf3 -c $target_ip
    fi
  else
    echo "无效的选择。"
  fi
}
# 第五个菜单选项：运行besttrace
run_besttrace() {
  echo -e "${GREEN}开始执行 besttrace 命令...\n"

  read -p "请输入您的本地IP地址： " local_ip

  # 检查是否已安装besttrace
  if ! command -v besttrace &>/dev/null; then
    echo -e "${YELLOW}未找到 besttrace，正在尝试下载并解压...\n"

    # 尝试两个下载地址
    download_urls=(
      "https://cdn.ipip.net/17mon/besttrace4linux.zip"
      "http://soft.xiaoz.org/linux/besttrace4linux.zip"
    )

    # 下载并解压besttrace4linux.zip文件
    for url in "${download_urls[@]}"; do
      echo "正在尝试下载 $url ..."
      if command -v wget &>/dev/null; then
        wget "$url" -O besttrace4linux.zip
      elif command -v curl &>/dev/null; then
        curl -o besttrace4linux.zip "$url"
      else
        echo -e "${RED}无法下载文件，请确保安装了wget或curl。\n"
        return 1
      fi

      # 检查下载的zip文件是否存在
      if [ -f "besttrace4linux.zip" ]; then
        unzip besttrace4linux.zip
        chmod +x besttrace
        mv besttrace /usr/local/bin/   # 或者你可以移动到其他系统路径中

        # 检查besttrace是否安装成功
        if command -v besttrace &>/dev/null; then
          break  # 如果成功安装则跳出循环
        else
          echo -e "${RED}无法安装 besttrace。\n"
          return 1
        fi
      else
        echo -e "${RED}下载的 zip 文件不存在。\n"
      fi
    done
  fi

  # 执行besttrace命令
  echo "执行 besttrace 命令，跟踪至中国的路由..."
  besttrace -q1 -g cn "$local_ip"

  echo -e "${RESET}\nbesttrace 命令执行完成。\n"
}

# Dnsmasq解锁Netflix安装、卸载和附加功能菜单
dnsmasq_netflix_manage() {
  while true; do
    echo "请选择操作："
    echo "1. 安装 Dnsmasq 解锁 Netflix"
    echo "2. 卸载 Dnsmasq 解锁 Netflix"
    echo "3. 附加功能"
    echo "4. 返回上一页"
    read -p "请输入选项（1/2/3/4）：" choice

    case $choice in
      1)
        install_dnsmasq_netflix
        ;;
      2)
        uninstall_dnsmasq_netflix
        ;;
      3)
        additional_dnsmasq_functions
        ;;
      4)
        return
        ;;
      *)
        echo "无效选择，请重新输入。"
        continue
        ;;
    esac
  done
}

# 一键DD功能
one_click_dd() {
  echo "正在下载一键DD脚本..."
  wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/installNET/master/Install.sh"
  echo "添加执行权限..."
  chmod +x Install.sh
  echo "运行一键DD脚本..."
  ./Install.sh
}

# 主菜单
main_menu() {
  while true; do
    echo "请选择操作："
    echo "1. 安装必要脚本"
    echo "2. 安装 Docker"
    echo "3. 一键安装 XrayR"
    echo "4. 安装 iptables"
    echo "5. 返回上一页（Dnsmasq解锁Netflix菜单）"
    read -p "请输入序号： " choice

    case $choice in
      1) install_network_tools_and_bbr ;;
      2) install_docker ;;
      3) install_xrayr ;;
      4) install_iptables ;;
      5) return ;;
      *)
        echo "无效选择，请重新输入。"
        continue
        ;;
    esac
  done
}

# 主程序
while true; do
  # 主菜单
  menu() {
    echo -e "${GREEN}请选择操作："
    echo -e "1. 安装必要脚本"
    echo -e "2. 安装 Docker"
    echo -e "3. 一键安装 XrayR"
    echo -e "4. 一键安装 iptables"
    echo -e "5. Speedtest 测试"
    echo -e "6. 关闭 IPv6"
    echo -e "7. 设置定时重启任务"
    echo -e "8. 安装性能测试工具 wrk"
    echo -e "9. DNS修改"
    echo -e "10. 流媒体解锁"
    echo -e "11. 使用 tcptraceroute"
    echo -e "12. 使用 iperf3 网络测试"
    echo -e "13. 运行 besttrace 跟踪回城路由"
    echo -e "14. Dnsmasq解锁Netflix管理"  # 添加一个新选项
    echo -e "15. 一键DD系统"
    echo -e "16. 退出${RESET}"
    read -p "请输入序号： " choice
    
    case $choice in
      1) install_network_tools_and_bbr ;;
      2) install_docker ;;
      3) install_xrayr ;;
      4) install_iptables ;;
      5) install_speedtest ;;
      6) disable_ipv6 ;;
      7) schedule_reboot ;;
      8) install_wrk ;;
      9) modify_dns ;;
      10) streaming_unlock ;;
      11) use_tcptraceroute ;;
      12) use_iperf3 ;;
      13) run_besttrace ;;
      14) dnsmasq_netflix_manage ;;  # 调用 Dnsmasq 解锁 Netflix 管理函数
      15) one_click_dd ;;  # 调用一键DD功能
      16)
        echo -e "${MAGENTA}退出程序。${RESET}"
        exit 0
        ;;
      *)
        echo -e "${RED}无效选择，请重新输入。${RESET}"
        ;;
    esac
  }

  menu  # 调用主菜单函数
done
