#!/bin/bash

# 菜单
menu() {
  echo "请选择操作："
  echo "1. 安装必要脚本"
  echo "2. 安装 Docker"
  echo "3. 一键安装 XrayR"
  echo "4. 一键安装 iptables"
  echo "5. 退出"
  read -p "请输入序号： " choice
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
      echo "退出程序。"
      exit 0
      ;;
    *)
      echo "无效选择，请重新输入。"
      ;;
  esac
done
