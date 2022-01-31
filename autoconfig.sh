#!/bin/bash
OS_U=Ubuntu
OS_D=Debian
OS_A=AlmaLinux
OS_C=CentOS

function func_start()
{
  echo " __  ___   __    _   ___         __            "
  echo "|  |  |   |  |  | \   |   |  |  |    |\  /|  | "
  echo "|     |   |__|  |_/   |   |__|  |--  | \/ |  | "
  echo "|__|  |   |  |  |     |    __|  |__  |    |  . "
  echo
  secs=$((3))
  while [ $secs -gt 0 ]; do
    echo -ne "Start in $secs\033[0K\r"
    sleep 1
    : $((secs--))
  done
  echo -ne " \033[0K\r"
}

function func_hostname()
{
  echo -e "\033[4mHostname:\033[0m"
  hostname
  echo
  while true; do
   read -p "Do you need a new hostname?(Y/N) " yn
   case $yn in
     [Yy]* ) echo "Enter new hostname: "
            read hname;
            hostnamectl set-hostname $hname;
            echo -e "\033[32mDone\033[0m";
            echo
            break;;
    [Nn]* ) break;;
    * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
  esac
  done
}

function func_ubuntu_netplan()
{
  while true; do
    read -p "Do you need a new network settings?(Y/N): " yn
    case $yn in
      [Yy]* ) echo "Enter new IP address: "
              read np_ip;
              echo
              echo "Enter new netmask (24): "
              read np_mask;
              echo
              echo "Enter new GW: "
              read np_gw;
              echo
              echo "Enter new DNS1: "
              read np_dns1;
              echo
              echo "Enter new DNS2: "
              read np_dns2;
              echo
              echo "Enter new search domaine: "
              read np_sd;
              echo
              s_list=$(ifconfig -s | awk '{print $1;}')
              eval "arr=($s_list)"
              unset arr[0]
              echo "Network interfaces:"
              PS3="Choose an inerface: "
              COLUMNS=0
              select inst in "${arr[@]}" Next; do
                case $inst in
                  [${arr[@]}]* ) int_name=$inst
                                 break;;
                          Next ) break;;
                             * ) echo "$REPLY is not a valid number, please retry";;
                esac
              done
            configfile=$(ls -d /etc/netplan/*)
            sudo cat << EOF > $configfile
network:
  ethernets:
    $int_name:
      addresses:
      - $np_ip/$np_mask
      gateway4: $np_gw
      nameservers:
        addresses:
        - $np_dns1
        - $np_dns2
        search:
        - $np_sd
  version: 2
EOF
            echo -e "\033[32mConfig is saved\033[0m"
            echo
            if sudo netplan --debug generate | grep 'Configuration is valid'
            then
              echo "Config is Ok, appling it..."
              sudo netplan apply
              echo -e "\033[32mDone\033[0m"
            else
              echo -e "\033[31mConfig is not Ok, check it!\033[0m"
              sudo netplan --debug generate
            fi
            echo
            echo "Network settings:"
            cat $configfile
            break;;
    [Nn]* ) break;;
        * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
    esac
  done
}

function func_ubuntu_classic_int
{
  while true; do
    read -p "Do you need a new network settings?(Y/N): " yn
    case $yn in
      [Yy]* ) echo "Enter new IP address: "
            read int_ip;
            echo
            echo "Enter new netmask (255.255.255.0): "
            read int_mask;
            echo
            echo "Enter new GW: "
            read int_gw;
            echo
            echo "Enter new DNS1: "
            read int_dns1;
            echo
            echo "Enter new DNS2: "
            read int_dns2;
            echo
            echo "Enter new search domaine: "
            read int_sd;
            echo
            s_list=$(ifconfig -s | awk '{print $1;}')
            eval "arr=($s_list)"
            unset arr[0]
            echo "Network interfaces:"
            PS3="Choose an inerface: "
            COLUMNS=0
            select inst in "${arr[@]}" Next; do
              case $inst in
                [${arr[@]}]* ) int_name=$inst
                               break;;
                Next) break;;
                *) echo "$REPLY is not a valid number, please retry";;
              esac
            done
            configfile="/etc/network/interfaces"
            cat << EOF > $configfile
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto $int_name
iface $int_name inet static
address $int_ip
gateway $int_gw
netmask $int_mask

EOF
            echo
            echo "Network config is saved"
            echo

            dpkg -l | grep resolvconf
            if [ $? -eq 0 ]
            then
              echo "Resolvconf is installed"
              echo 'dns-nameservers $int_dns1 $int_dns2' >> $configfile
            else
              dns_configfile="/etc/resolv.conf"
              cat << EOF > $dns_configfile
domain $int_sd
search $int_sd
nameserver $int_dns1
nameserver $int_dns2
EOF
              echo "DNS config is saved"
            fi
            echo
            echo "Always good to Reboot!"
            sudo service network-manager restart
            echo
            break;;
    [Nn]* ) break;;
        * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
    esac
  done
}

function func_utilities()
{
  echo -e "\033[4mInstalling utilities\033[0m"
  echo
  check_=(sudo ufw bc openssh-server)
  for i in ${check_[@]}
  do
    if [ $(dpkg-query -W -f='${Status}' $i 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
      echo "$i is not installed"
      apt install $i -y
    else
      echo "$i is allready installed"
    fi
  done
  echo
  echo "Utilities list:"
  echo "mc nethogs htop net-tools"
  echo
  while true; do
    read -p "Do you want to install these utilities?(Y/N) " yn
    case $yn in
      [Yy]* ) sudo apt install mc -y; sudo apt install nethogs -y; sudo apt install htop -y; sudo apt install net-tools -y; break;;
      [Nn]* ) break;;
          * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
    esac
  done
}

function isinstalled()
{
  if yum list installed "$@" >/dev/null 2>&1; then
    true
  else
    false
  fi
}

function func_utilities_AC()
{
  soft_=(mc epel-release htop net-tools)
  echo
  echo -e "\033[4mUtilities\033[0m"
  echo
  while true; do
    read -p "Install base utilities?(Y/N) " yn
    case $yn in
      [Yy]* ) while true; do
                echo "Install utilities"
                selections=("${soft_[@]}" "All" "Next")
                choose_from_menu "Please make a choice:" selected_choice "${selections[@]}"
                echo "Selected choice: $selected_choice"
                if [ $selected_choice == "Next" ]
                then
                  break
                elif [ $selected_choice == "All" ]
                then
                  for i in ${soft_[@]}
                  do
                    if isinstalled $i
                    then
                      echo "$i installed"
                    else
                      echo "$i not installed"
                      sudo yum install $i -y;
                      echo -e "\033[32mDone\033[0m"
                      echo
                    fi
                  done
                else
                  if isinstalled $selected_choice
                  then
                    echo "$selected_choice installed"
                    echo
                    else
                    echo "$selected_choice not installed"
                    sudo yum install $selected_choice -y;
                    echo -e "\033[32mDone\033[0m"
                    echo
                  fi
                fi
              echo
              done
              break;;
      [Nn]* ) break;;
          * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
    esac
  done
}

function choose_from_menu()
{
    eq_list=$(echo ${arr_list[@]} ${arr_new_list[@]} | tr ' ' '\n' | sort | uniq -u)
    eval "arr_eq_list=($eq_list)"
    local prompt="$1" outvar="$2"
    shift
    shift
    local options=("$@") cur=0 count=${#options[@]} index=0
    local esc=$(echo -en "\e") # cache ESC as test doesn't allow esc codes
    printf "$prompt\n"
    while true
    do
        # list all options (option list is zero-based)
        index=0
        for o in "${options[@]}"
        do
            if [ "$index" == "$cur" ]
            then echo -e " >\e[32m$o\e[0m" # mark & highlight the current option
            else echo "  $o"
            fi
            index=$(( $index + 1 ))
        done
        read -s -n3 key # wait for user to key in arrows or ENTER
        if [[ $key == $esc[A ]] # up arrow
        then cur=$(( $cur - 1 ))
            [ "$cur" -lt 0 ] && cur=0
        elif [[ $key == $esc[B ]] # down arrow
        then cur=$(( $cur + 1 ))
            [ "$cur" -ge $count ] && cur=$(( $count - 1 ))
        elif [[ $key == "" ]] # nothing, i.e the read delimiter - ENTER
        then break
        fi
        echo -en "\e[${count}A" # go up to the beginning to re-render
    done
    # export the selection to the requested output variable
    printf -v $outvar "${options[$cur]}"
}

function func_ufw()
{
  arr_new_list=(domain http https ssh syslog zabbix-agent)
  echo "Firewall settings:"
  sudo ufw status verbose
  while true; do
    read -p "Do you need a new firewall settings?(Y/N) " yn
    case $yn in
      [Yy]* ) #----- Service -----
              while true; do
                echo
                echo -e "\033[4mAdding services\033[0m"
                selections=("${arr_new_list[@]}" "Next")
                choose_from_menu "Please make a choice:" selected_choice "${selections[@]}"
                echo "Selected choice: $selected_choice"
                if [ $selected_choice == "Next" ]
                then
                  break
                else
                  sudo ufw allow $selected_choice
                  echo "Saving..."
                  secs=$((1))
                  while [ $secs -gt 0 ]; do
                    sleep 1
                    : $((secs--))
                  done
                  echo -e "\033[32mDone\033[0m"
                  echo
                  sudo ufw status verbose
                  echo
                fi
              done
              echo
              #----- Port -----
              arr_prot=(TCP UDP)
              while true; do
                echo
                echo -e "\033[4mAdding ports\033[0m"
                selections=("${arr_prot[@]}" "Quit")
                choose_from_menu "Please make a choice:" selected_choice "${selections[@]}"
                echo "Selected choice: $selected_choice"
                if [ $selected_choice == "TCP" ]
                then
                  prot="/tcp"
                  echo
                  echo "Enter port number, or port range (1:999): "
                  read p_num
                  sudo ufw allow $p_num$prot
                  echo
                  sudo ufw status verbose
                  echo -e "\033[32mDone\033[0m"
                  echo
                elif [ $selected_choice == "UDP" ]
                then
                  prot="/udp"
                  echo
                  echo "Enter port number, or port range (1:999): "
                  read p_num
                  sudo ufw allow $p_num$prot
                  echo
                  sudo ufw status verbose
                  echo -e "\033[32mDone\033[0m"
                  echo
                elif [ $selected_choice == "Quit" ]
                then
                  break
                fi
              done
              break;;
      [Nn]* ) break;;
          * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
    esac
  done
}

os_id=$(lsb_release -si)

#----- Ubuntu -----
if [[ $os_id == $OS_U ]]
then
  echo
  echo -e "\033[33mIt's Ubuntu!\033[0m"
  echo
  #----- Start -----
  func_start
  echo
  #----- Update -----
  echo -e "\033[4mUpdate/Upgrade system\033[0m"
  while true; do
    read -p "Do you whant to update?(Y/N) " yn
    case $yn in
      [Yy]* ) echo "--- Start update ---"
              sudo apt update
              sudo apt upgrade -y
              echo "--- Update complete ---"
              echo
              break;;
      [Nn]* ) break;;
          * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
     esac
  done
  echo
  #----- Utilities -----
  func_utilities
  echo
  #----- Hostname -----
  func_hostname
  echo
  #----- Network -----
  echo -e "\033[4mNetwork settings:\033[0m"
  ip a
  echo
  rel_num=$(lsb_release -sr)
  result=$(echo "$rel_num >= 18.04" | bc -l)
  if [ $result -eq 1 ]
    then
    echo "Netplan configuration"
    echo
    func_ubuntu_netplan
    echo
  else
    echo "Network configuration"
    echo
    func_ubuntu_classic_int
  fi
  #----- UFW -----
  echo -e "\033[4mFirewall settings\033[0m"
  ufw_status=$(sudo ufw status verbose | grep "Status: inactive")
  if [ $? -eq 0 ]
  then
    echo
    echo -e "UFW is\033[32m disable \033[0m"
    while true; do
      read -p "Do you whant to enable UFW?(Y/N) " yn
      case $yn in
        [Yy]* ) sudo ufw enable
                echo -e "\033[32mDone\033[0m"
                echo
                func_ufw
                break;;
        [Nn]* ) break;;
            * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
      esac
    done
  else
    echo
    echo -e "UFW is\033[32m enable \033[0m"
    while true; do
      read -p "Do you whant to disable UFW?(Y/N) " yn
      case $yn in
        [Yy]* ) sudo ufw disable
                echo -e "\033[32mDone\033[0m"
                break;;
        [Nn]* ) func_ufw
                break;;
            * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
      esac
    done
  fi
  echo
#----- Debian -----
elif [[ $os_id == $OS_D ]]
then
  echo
  echo -e "\033[33mIt's Debian!\033[0m"
  echo
  #----- Start -----
  func_start
  echo
  #----- Check repo -----
  line=$(head -n 1 /etc/apt/sources.list)
  c_line="deb http://deb.debian.org/debian/ bullseye main"
  if [[ "$line" == "$c_line" ]]
  then
    echo "Repo is correct"
  else
    echo "Fixing repo..."
    cat << EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian/ bullseye main
deb-src http://deb.debian.org/debian/ bullseye main
deb http://security.debian.org/debian-security bullseye-security main contrib
deb-src http://security.debian.org/debian-security bullseye-security main contrib
deb http://deb.debian.org/debian/ bullseye-updates main contrib
deb-src http://deb.debian.org/debian/ bullseye-updates main contrib
EOF
  echo -e "\033[32mDone\033[0m"
  echo
  fi
  #----- Update -----
  echo -e "\033[4mUpdate/Upgrade system\033[0m"
  while true; do
    read -p "Do you whant to update?(Y/N) " yn
    case $yn in
      [Yy]* ) echo "--- Start update ---"
              apt update
              apt upgrade -y
              echo "--- Update complete ---"
              echo
              break;;
      [Nn]* ) break;;
          * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
    esac
  done
  echo
  #----- Utilities -----
  func_utilities
  echo
  #----- Hostname -----
  func_hostname
  echo
  #----- Network -----
  echo -e "\033[4mNetwork settings:\033[0m"
  ip a
  echo
  while true; do
    read -p "Do you need a new network settings?(Y/N): " yn
    case $yn in
      [Yy]* ) echo "Enter new IP address: "
            read np_ip;
            echo
            echo "Enter new netmask (255.255.255.0): "
            read np_mask;
            echo
            echo "Enter new GW: "
            read np_gw;
            echo
            echo "Enter new DNS1: "
            read np_dns1;
            echo
            echo "Enter new DNS2: "
            read np_dns2;
            echo
            echo "Enter new search domaine: "
            read np_sd;
            echo
            s_list=$(ifconfig -s | awk '{print $1;}')
            eval "arr=($s_list)"
            unset arr[0]
            echo "Network interfaces:"
            PS3="Choose an inerface: "
            COLUMNS=0
            select inst in "${arr[@]}" Next; do
              case $inst in
                [${arr[@]}]* ) int_name=$inst
                               break;;
                        Next ) break;;
                           * ) echo "$REPLY is not a valid number, please retry";;
              esac
            done
            configfile="/etc/network/interfaces"
            cat << EOF > $configfile
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto $int_name
iface $int_name inet static
address $np_ip
gateway $np_gw
netmask $np_mask

EOF
            echo
            echo -e "\033[32mNetwork config is saved\033[0m"
            echo

            dpkg -l | grep resolvconf
            if [ $? -eq 0 ]
            then
              echo "Resolvconf is installed"
              echo 'dns-nameservers $np_dns1 $np_dns2' >> $configfile
            else
              dns_configfile="/etc/resolv.conf"
              cat << EOF > $dns_configfile
domain $np_sd
search $np_sd
nameserver $np_dns1
nameserver $np_dns2
EOF
              echo "DNS config is saved"
            fi
            echo
            echo "Always good to Reboot!"
            systemctl restart networking.service
            echo
            break;;
    [Nn]* ) break;;
        * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
    esac
  done
  #----- UFW -----
  echo -e "\033[4mFirewall settings\033[0m"
  ufw_status=$(sudo ufw status verbose | grep "Status: inactive")
  if [ $? -eq 0 ]
  then
    echo
    echo -e "UFW is\033[32m disable \033[0m"
    while true; do
      read -p "Do you whant to enable UFW?(Y/N) " yn
      case $yn in
        [Yy]* ) sudo ufw enable
                echo -e "\033[32mDone\033[0m"
                echo
                func_ufw
                break;;
        [Nn]* ) break;;
            * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
      esac
    done
  else
    echo
    echo -e "UFW is\033[32m enable \033[0m"
    while true; do
      read -p "Do you whant to disable UFW?(Y/N) " yn
      case $yn in
        [Yy]* ) sudo ufw disable
                echo -e "\033[32mDone\033[0m"
                break;;
        [Nn]* ) func_ufw
                break;;
            * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
      esac
    done
  fi
fi

#----- Almalinux/CentOS -----
hostnamectl | grep -E "AlmaLinux|CentOS"
if [ $? -eq 0 ]
then
  echo
  version=$"redhat-lsb-core"
  #----- lsb_release -----
  function isinstalled {
    if yum list installed "$@" >/dev/null 2>&1; then
      true
    else
      false
    fi
  }

  if isinstalled $version
    then
    echo "lsb_release installed"
    echo
    else
    echo "lsb_release not installed"
    yum install redhat-lsb-core -y
    echo -e "\033[32mDone\033[0m"
    echo
  fi

  os_id=$(lsb_release -si)
  #----- OS name -----
  if [[ $os_id == $OS_A ]]
  then
    echo -e "\033[33mIt's AlmaLinux!\033[0m"
  elif [[ $os_id == $OS_C ]]
  then
    echo -e "\033[33mIt's CentOS!\033[0m"
  fi
  #----- Start! -----
  echo
  func_start
  echo
  #----- Update -----
  echo -e "\033[4mUpdate/Upgrade system\033[0m"
  arr_u=(update upgrade)
  selections=("${arr_u[@]}" "Next")
  choose_from_menu "Please make a choice:" selected_choice "${selections[@]}"
  echo "Selected choice: $selected_choice"
  if [ $selected_choice == "update" ]
  then
    echo "--- Start update ---"
    sudo yum update -y
    echo "--- Update complete ---"
    echo
  elif [ $selected_choice == "upgrade" ]
  then
    echo "--- Start upgrade ---"
    sudo yum upgrade -y
    echo "--- Upgrade complete ---"
    echo
  fi
  echo
  #----- Utilities -----
#  echo -e "\033[4mInstalling utilities:\033[0m"
#  while true; do
#    read -p "Need some utilities?(Y/N) " yn
#    case $yn in
#      [Yy]* ) sudo yum -y install epel-release; sudo yum install mc -y; sudo yum install htop -y; sudo yum install net-tools -y; break;;
#      [Nn]* ) break;;
#          * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
#    esac
#  done
  func_utilities_AC
  echo
  #----- Hostname -----
  func_hostname
  echo
  #----- Network -----
  echo -e "\033[4mNetwork settings:\033[0m"
  ip a
  echo
  while true; do
    read -p "Do you need a new network settings?(Y/N): " yn
    case $yn in
      [Yy]* ) echo "Enter new IP address: "
              read int_ip;
              echo
              echo "Enter new netmask (24): "
              read int_mask;
              echo
              echo "Enter new GW: "
              read int_gw;
              echo
              echo "Enter new DNS1: "
              read int_dns1;
              echo
              echo "Enter new DNS2: "
              read int_dns2;
              echo
              s_list=$(ifconfig -s | awk '{print $1;}')
              eval "arr=($s_list)"
              unset arr[0]
              echo "Network interfaces:"
              PS3="Choose an inerface: "
              COLUMNS=0
              select inst in "${arr[@]}" Next; do
                case $inst in
                  [${arr[@]}]* ) int_name=$inst; break;;
                          Next ) break;;
                             * ) echo "$REPLY is not a valid number, please retry";;
                esac
              done
              sudo nmcli connection modify $int_name IPv4.address $int_ip/$int_mask
              sudo nmcli connection modify $int_name IPv4.gateway $int_gw
              sudo nmcli connection modify $int_name IPv4.dns "$int_dns1 $int_dns2"
              sudo nmcli connection modify $int_name IPv4.method manual
              sudo nmcli connection down $int_name && nmcli connection up $int_name
              echo
              echo "New network settings:"
              ip a
              break;;
      [Nn]* ) break;;
          * ) echo echo -e "\033[31mPlease answer yes or no.\033[0m";;
    esac
  done
  arr_new_list=(cockpit dhcp dhcpv6-client dns docker-registry docker-swarm http https samba samba-client ssh syslog zabbix-agent)
  s_list=$(sudo firewall-cmd --list-services)
  eval "arr_list=($s_list)"
  eq_list=$(echo ${arr_list[@]} ${arr_new_list[@]} | tr ' ' '\n' | sort | uniq -u)
  eval "arr_eq_list=($eq_list)"
  echo
  echo -e "\033[4mFirewall settings:\033[0m"
  sudo firewall-cmd --list-all
  echo
  while true; do
    read -p "Do you need a new firewall settings?(Y/N) " yn
    case $yn in
      [Yy]* ) #----- Service -----
              while true; do
                echo "Adding services"
                selections=("${arr_eq_list[@]}" "Next")
                choose_from_menu "Please make a choice:" selected_choice "${selections[@]}"
                echo "Selected choice: $selected_choice"
                if [ $selected_choice == "Next" ]
                then
                  break
                else
                  sudo firewall-cmd --zone=public --add-service=$selected_choice
                  sudo firewall-cmd --zone=public --add-service=$selected_choice --permanent
                  echo "Saving..."
                  secs=$((1))
                  while [ $secs -gt 0 ]; do
                    sleep 1
                    : $((secs--))
                  done
                  echo "Done"
                  s_list=$(sudo firewall-cmd --list-services)
                  eval "arr_list=($s_list)"
                  eq_list=$(echo ${arr_list[@]} ${arr_new_list[@]} | tr ' ' '\n' | sort | uniq -u)
                  eval "arr_eq_list=($eq_list)"
                  echo
                  echo "Services:"
                  echo "${arr_list[@]}"
                  echo
                fi
              done
              echo
              #----- Port -----
              arr_prot=(TCP UDP)
              while true; do
                echo "Adding ports"
                selections=("${arr_prot[@]}" "Next")
                choose_from_menu "Please make a choice:" selected_choice "${selections[@]}"
                echo "Selected choice: $selected_choice"
                if [ $selected_choice == "TCP" ]
                then
                  prot="/tcp"
                  echo
                  echo "Enter port number, or port range (1-999): "
                  read p_num
                  sudo firewall-cmd --zone=public --add-port=$p_num$prot
                  sudo firewall-cmd --zone=public --permanent --add-port=$p_num$prot
                  echo
                  echo "Open ports:"
                  sudo firewall-cmd --zone=public --permanent --list-ports
                  echo "Done"
                elif [ $selected_choice == "UDP" ]
                then
                  prot="/udp"
                  echo
                  echo "Enter port number, or port range (1-999): "
                  read p_num
                  sudo firewall-cmd --zone=public --add-port=$p_num$prot
                  sudo firewall-cmd --zone=public --permanent --add-port=$p_num$prot
                  echo
                  echo "Open ports:"
                  sudo firewall-cmd --zone=public --permanent --list-ports
                  echo -e "\033[32mDone\033[0m"
                elif [ $selected_choice == "Next" ]
                then
                  break
                fi
              done
              #----- SELinux -----
              echo
              sestatus | grep "SELinux status"
              se_status=$(getenforce)
              echo
              if [ "$se_status" == "Enforcing" ]
              then
                while true; do
                  read -p "Disable the SELinux?(Y/N) " yn
                  case $yn in
                    [Yy]* ) sudo setenforce 0
                            sudo sed -i s/SELINUX=enforcing/SELINUX=disabled/ /etc/selinux/config
                            echo "Done, SELinux is in Permissive status. For Disable mode need to reboot!"
                            break;;
                    [Nn]* ) break;;
                        * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
                  esac
                done
              elif [ "$se_status" == "Permissive" ]
              then
                echo "SELinux is in Permissive status"
                while true; do
                  read -p "Disable the SELinux?(Y/N) " yn
                  case $yn in
                    [Yy]* ) sudo sed -i s/SELINUX=enforcing/SELINUX=disabled/ /etc/selinux/config
                            echo
                            echo "Done, need to reboot!"
                            break;;
                    [Nn]* ) break;;
                        * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
                  esac
                done
              else
                echo "SELinux is already Disabled"
              fi
              break;;
      [Nn]* ) break;;
          * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
    esac
  done
else
  echo
fi
echo
while true; do
  read -p "Need reboot?(Y/N) " yn
  case $yn in
    [Yy]* ) echo -e "\033[32mRebooting system...\033[0m"
            echo
            secs=$((3))
            while [ $secs -gt 0 ]; do
              sleep 1
              : $((secs--))
            done
            sudo reboot
            break;;
    [Nn]* ) break;;
        * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
  esac
done

echo
echo "That's all folks!"
echo

exit  0
