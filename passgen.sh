#!/bin/bash
echo "---Password generator--"; echo

function func_generator()
{
  SUCCESS=0
  FAILURE=-1

  while true; do
    read -p "Use number?(Y/N) " yn
    case $yn in
      [Yy]* ) num_="n"
              break;;
      [Nn]* ) num_="0"
              break;;
          * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
    esac
  done

  while true; do
    read -p "Use capital letters?(Y/N) " yn
    case $yn in
      [Yy]* ) cl_="c"
              break;;
      [Nn]* ) cl_="A"
              break;;
          * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
    esac
  done

  while true; do
    read -p "Use special character (symbols)?(Y/N) " yn
    case $yn in
      [Yy]* ) sch_="y"
              break;;
      [Nn]* ) break;;
          * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
    esac
  done

  while true; do
    read -p "Use ambiguous characters?(Y/N) " yn
    case $yn in
      [Yy]* ) amb_="B"
              break;;
      [Nn]* ) break;;
          * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
    esac
  done

  isdigit()
  {
    [ $# -eq 1 ] || return $FAILURE

    case $1 in
    *[!0-9]*|"") return $FAILURE;;
              *) return $SUCCESS;;
    esac
  }

  read -p "Password(s) length: " p_length
  until false; do
    if isdigit $p_length
    then
      echo
      break
    else
      echo "Incorrect valume!"
      read -p "Password(s) length: " p_length
    fi
  done

  read -p "Number of generated passwords: " number
  until false; do
    if isdigit $number
    then
      echo
      break
    else
      echo "Incorrect valume!"
      read -p "Number of generated passwords: " number
    fi
  done

  options="$num_ $cl_ $amb_ $sch_"
  option_=$(echo $options | tr -d '[:space:]')
  echo
  echo "Password is:"
  pwgen -1s"$option_" "$p_length" "$number"
  #echo "-1s$option_"
}

if [ $(dpkg-query -W -f='${Status}' "pwgen" 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    echo "pwgen is not installed"
    while true; do
      read -p "Do you whant to install pwgen?(Y/N) " yn
      case $yn in
        [Yy]* ) sudo apt update
                sudo apt install pwgen -y
                echo "Done"; echo
                func_generator
                break;;
        [Nn]* ) echo "Ok, no pwgen, no password."
                break;;
            * ) echo -e "\033[31mPlease answer yes or no.\033[0m";;
      esac
    done
else
  echo "pwgen is allready installed"; echo
  func_generator
fi
