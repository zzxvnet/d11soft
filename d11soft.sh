#!/bin/bash

# 菜单
menu() {
  echo "请选择操作："
  echo "1. 安装必要脚本"
  echo "2. 安装 Docker"
  echo "3. 一键安装 XrayR"
  echo "4. 一键安装 iptables"
  echo "5. Speedtest 测试"
  echo "6. 退出"
  read -p "请输入序号： " choice
}

# ... 其他函数 ...

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
      echo "退出程序。"
      exit 0
      ;;
    *)
      echo "无效选择，请重新输入。"
      ;;
  esac
done
