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

# 菜单
menu() {
  echo -e "${GREEN}请选择操作："
  echo -e "1. 安装必要脚本"
  echo -e "2. 安装 Docker"
  echo -e "3. 一键安装 XrayR"
  echo -e "4. 一键安装 iptables"
  echo -e "5. Speedtest 测试"
  echo -e "6. 关闭 IPv6"
  echo -e "7. 设置定时重启任务"
  echo -e "8. 退出${RESET}"
  read -p "请输入序号： " choice
}


# 设置定时重启任务
schedule_reboot() {
  echo -e "${YELLOW}请选择定时重启任务的类型："
  echo -e "1. 每天早上5点重启系统"
  echo -e "2. 自定义重启时间${RESET}"
  read -p "请输入选择的序号： " reboot_choice

  case $reboot_choice in
    1)
      echo -e "${GREEN}正在设置标准定时重启任务..."
      # 创建标准的每天早上5点重启的定时任务
      echo "0 5 * * * root /sbin/reboot" | sudo tee -a /etc/crontab
      echo "标准定时重启任务已设置，每天早上5点将进行系统重启。${RESET}"
      ;;
    2)
      echo -e "${GREEN}请输入自定义的定时重启时间，例如：每天下午3点重启系统，输入：15 0"
      read -p "请输入定时任务的时间设置： " custom_time
      # 创建自定义时间的定时任务
      echo "$custom_time * * * root /sbin/reboot" | sudo tee -a /etc/crontab
      echo -e "自定义定时重启任务已设置，每天$custom_time将进行系统重启。${RESET}"
      ;;
    *)
      echo -e "${RED}无效选择，请重新输入。${RESET}"
      ;;
  esac

  # 显示当前的定时任务列表
  echo -e "${BLUE}当前定时任务列表："
  sudo crontab -l
  echo -e "${RESET}"
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

# 一键安装 iptables
install_iptables() {
  echo "正在下载 iptables 安装脚本..."
  wget -q -O iptables_install.sh --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/iptables-pf.sh
  chmod +x iptables_install.sh
  echo "下载完成。"

  # 询问用户是否要安装 iptables
  while true; do
    read -p "是否要安装 iptables？[Y/n] " yn
    case $yn in
      [Yy]* ) 
        echo "正在安装 iptables..."
        bash iptables_install.sh
        break
        ;;
      [Nn]* ) 
        echo "跳过安装 iptables。"
        break
        ;;
      * )
        echo "请输入 Y (yes) 或者 N (no)。"
        ;;
    esac
  done
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



# 主程序
while true; do
  menu
  case $choice in
    1)
      install_network_tools_and_bbr
      ;;
    2)
      install_docker
      ;;
    3)
      install_xrayr
      ;;
    4)
      install_iptables
      ;;
    5)
      install_speedtest
      ;;
    6)
      disable_ipv6  # 调用关闭 IPv6 的函数
      ;;
    7)
      schedule_reboot  # 调用设置定时重启任务的函数
      ;;
    8)
      echo -e "${MAGENTA}退出程序。${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}无效选择，请重新输入。${RESET}"
      ;;
  esac
done
