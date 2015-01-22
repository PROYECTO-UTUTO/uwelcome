#!/bin/bash
# select_cpu-type.sh - shell script
#
# Autor: Martin Andres Gomez Gimenez <mggimenez@ututo.org>
#
# Copyright (C) 2004 - 2008 The UTUTO Project
# Distributed under the terms of the GNU General Public License v3 or new
#
# $Header: $



# This script are defined for the i386 and x86-64 family of computers.See 
# Submodel Options for Intel 386 and AMD x86-64 on GCC documentation.



# Set default parameters
VERSION="1.0.0"
OPTION="march"



# AMD processors
declare -a AuthenticAMD
declare -a AMD_cpu_family5
declare -a AMD_cpu_family6
declare -a AMD_cpu_family15
declare -a AMD_cpu_family16
declare -a AMD_cpu_family17
declare -a UTUTO_AMD_cpu_family5
declare -a UTUTO_AMD_cpu_family6
declare -a UTUTO_AMD_cpu_family15
declare -a UTUTO_AMD_cpu_family16
declare -a UTUTO_AMD_cpu_family17

# Array of families for AMD processors
AuthenticAMD=(
  [5]="AMD_cpu_family5"
  [6]="AMD_cpu_family6"
  [15]="AMD_cpu_family15"
  [16]="AMD_cpu_family16"
  [17]="AMD_cpu_family17"
)

# Array of CPU types for AMD's models on family 5
AMD_cpu_family5=(
  [8]="k6"
  [10]="k6-2"
  [13]="k6-3"
)

# Array of CPU types for AMD's models on family 6
AMD_cpu_family6=(
  [2]="athlon"
  [3]="athlon-tbird"
  [4]="athlon"
  [6]="athlon-xp"
  [7]="athlon-xp"
  [8]="athlon-xp"
  [10]="athlon-mp"
)

# Array of CPU types for AMD's models on family 15
AMD_cpu_family15=(
  [4]="k8"
  [5]="opteron"
  [12]="k8"
  [15]="athlon-xp"
  [28]="athlon-xp"
  [31]="k8"
  [33]="opteron"
  [35]="k8"
  [36]="k8"
  [43]="k8"
  [44]="athlon-xp"
  [47]="k8"
  [63]="k8"
  [63]="opteron"
  [67]="Athlon64-X2"
  [75]="k8"
  [76]="athlon-xp"
  [79]="k8"
  [108]="k8"
  [107]="k8"
)

# Array of CPU types for AMD's models on family 16
AMD_cpu_family16=(
  [2]="k8"
  [4]="PhenomII"
)

# Array of CPU types for AMD's models on family 17
AMD_cpu_family17=(
  [3]="k8"
)


# UTUTO's CPU types for AMD families processors

# Array of UTUTO's CPU types for AMD's models on family 5
UTUTO_AMD_cpu_family5=(
  [8]="i486"
  [10]="i486"
  [13]="i486"
)

# Array of UTUTO's CPU types for AMD's models on family 6
UTUTO_AMD_cpu_family6=(
  [2]="duron-athlon"
  [3]="duron-athlon"
  [4]="duron-athlon"
  [6]="athlon-xp"
  [7]="athlon-xp"
  [8]="athlon-xp"
  [10]="athlon-mp"
)

# Array of UTUTO's CPU types for AMD's models on family 15
UTUTO_AMD_cpu_family15=(
  [4]="k8"
  [5]="k8"
  [12]="k8"
  [15]="athlon-xp"
  [28]="athlon-xp"
  [31]="k8"
  [33]="k8"
  [35]="k8"
  [36]="k8"
  [43]="k8"
  [44]="athlon-xp"
  [47]="k8"
  [63]="k8"
  [63]="k8"
  [67]="k8"
  [75]="k8"
  [76]="athlon-xp"
  [79]="k8"
  [104]="K8"
  [107]="k8"
)

# Array of UTUTO's CPU types for AMD's models on family 16
UTUTO_AMD_cpu_family16=(
  [2]="k8"
  [4]="k8"
)

# Array of UTUTO's CPU types for AMD's models on family 17
UTUTO_AMD_cpu_family17=(
  [3]="k8"
)


# INTEL processors
declare -a GenuineIntel
declare -a Intel_cpu_family5
declare -a Intel_cpu_family6
declare -a Intel_cpu_family15
declare -a UTUTO_Intel_cpu_family5
declare -a UTUTO_Intel_cpu_family6
declare -a UTUTO_Intel_cpu_family15

# Array of families for Intel processors
GenuineIntel=(
  [5]="Intel_cpu_family5"
  [6]="Intel_cpu_family6"
  [15]="Intel_cpu_family15"
)

# Array of CPU types for Intel's models on family 5
Intel_cpu_family5=(
  [2]="pentium"
  [4]="pentiumpro"
)

# Array of CPU types for Intel's models on family 6
Intel_cpu_family6=(
  [1]="pentiumpro"
  [3]="pentium2"
  [5]="pentium2"
  [6]="pentium2"
  [7]="pentium3"
  [8]="pentium3"
  [9]="pentium-m"
  [11]="pentium-m"
  [13]="pentium-m"
  [14]="pentium-m"
  [15]="Core2"
  [22]="IntelCore"
  [23]="Core2"
  [26]="Corei7"
  [28]="atom"
  [37]="Corei5"
  [42]="Corei3"
)

# Array of CPU types for Intel's models on family 15
Intel_cpu_family15=(
  [0]="pentium4"
  [1]="pentium4"
  [2]="pentium4"
  [3]="prescott"
  [4]="prescott"
  [6]="prescott"
  [9]="pentium-m"
  [13]="pentium-m"
)



# UTUTO's CPU types for Intel families processors

# Array of UTUTO's CPU types for Intel's models on family 5
UTUTO_Intel_cpu_family5=(
  [2]="i486"
  [4]="i686"
)

# Array of UTUTO's CPU types for Intel's models on family 6
UTUTO_Intel_cpu_family6=(
  [1]="i686"
  [3]="i686"
  [5]="i686"
  [6]="i686"
  [7]="pentium3"
  [8]="pentium3"
  [9]="pentium3"
  [11]="pentium3"
  [13]="pentium3"
  [14]="pentium3"
  [15]="nocona"
  [22]="nocona"
  [23]="nocona"
  [26]="nocona"
  [28]="atom"
  [37]="nocona"
  [42]="nocona"
)

# Array of UTUTO's CPU types for Intel's models on family 15
UTUTO_Intel_cpu_family15=(
  [0]="pentium4"
  [1]="pentium4"
  [2]="pentium4"
  [3]="pentium4"
  [4]="pentium4"
  [6]="pentium4"
  [9]="pentium3"
  [13]="pentium3"
)



# Transmeta processors
declare -a GenuineTMx86
declare -a Transmeta_cpu_family6
declare -a Transmeta_cpu_family15
declare -a UTUTO_Transmeta_cpu_family6
declare -a UTUTO_Transmeta_cpu_family15

# Array of families for Transmeta processors
GenuineTMx86=(
  [6]="Transmeta_cpu_family6"
  [15]="Transmeta_cpu_family15"
)

# Array of CPU types for Transmeta's models on family 6
Transmeta_cpu_family6=(
  [4]="i586"
)

# Array of CPU types for Transmeta's models on family 15
Transmeta_cpu_family15=(
  [2]="pentium3"
)



# UTUTO's CPU types for Transmeta families processors

# Array of UTUTO's CPU types for Transmeta's models on family 6
UTUTO_Transmeta_cpu_family6=(
  [4]="i486"
)

# Array of UTUTO's CPU types for Transmeta's models on family 15
UTUTO_Transmeta_cpu_family15=(
  [2]="pentium3"
)



# Function for print select_cpu-type.sh version
print_version () {
  local WHITE="\033[1m"
  local NO_COLOUR="\033[0m"
  
  echo -e "$WHITE""select_cpu-type.sh $VERSION""$NO_COLOUR"
  echo -e "Copyright (C) 2007 The UTUTO Project."
  echo -e "License GPLv3+: GNU GPL version 3 or later" \
        "<http://gnu.org/licenses/gpl.html>"
  echo -e "This is free software: you are free to change and redistribute it."
  echo -e "There is NO WARRANTY, to the extent permitted by law."
  echo -e
}


# Function for print help
print_help () {
  print_version
  echo -e
  echo -e "select_cpu-type.sh show details such as CPU type, type of machine" \
          "and UTUTO's"
  echo -e "CPU type on i386 and x86-64 family of computers."
  echo -e
  echo -e "Usage: select_cpu-type.sh [OPTION]"
  echo -e "Without option show CPU type."
  echo -e "OPTIONS:"
  echo -e " -h, --help" "\t\t" "Show this help and finish."
  echo -e " -m, --march" "\t\t" "Show CPU type."
  echo -e " -u, --march-ututo" "\t" "Show UTUTO's CPU type, useful for choose" \
          "a binary" 
  echo -e "\t\t\t" "package repository."
  echo -e " -v, --version" "\t\t" "Show version and finish."
  echo -e
  echo -e "Report bugs to mggimenez@ututo.org"
  echo -e
}



# Command-line options parsing by the getopt(1) program.
OPTIONS=`getopt \
  --options h,m,u,v --longoptions help,march,march-ututo,version \
  --name select_cpu-type.sh -- "$@"`

if [ $? != 0 ] ; then 
  echo "Terminating..." >&2 
  exit 1 
fi

eval set -- "$OPTIONS"

while true; do

  case "$1" in
    -h | --help ) 
      print_help
      exit 1
      ;;
    -m | --march ) 
      OPTION="march"
      shift
      ;;
    -u | --march-ututo ) 
      OPTION="march-ututo"
      shift
      ;;
    -v | --version ) 
      print_version
      exit 1
      ;;
    -- ) 
      shift
      break 
      ;;
    * ) 
      echo "Internal error!" 
      exit 1
      ;;
  esac

done



# Auto detect CPU
VENDOR_DETECTED=`awk -F :\  /^vendor_id/'{print $2}' /proc/cpuinfo | head -n 1`
FAMILY_DETECTED=`awk -F :\  /^cpu\ family/'{print $2}' /proc/cpuinfo | head -n 1`
MODEL_DETECTED=`awk -F :\  /^model/'{print $2}' /proc/cpuinfo | head -n 1`



# Vendor selector
case $VENDOR_DETECTED in
  "AuthenticAMD" )
    family="${AuthenticAMD[$FAMILY_DETECTED]}"
    ;;
  "GenuineIntel" )
    family="${GenuineIntel[$FAMILY_DETECTED]}"
    ;;
  "GenuineTMx86" )
    family="${GenuineTMx86[$FAMILY_DETECTED]}"
    ;;
  * )
    echo "NONE"
    ;;
esac



# Return CPU type
cpu_type () {

  case $1 in
    "AMD_cpu_family5" )
      echo "${AMD_cpu_family5[$MODEL_DETECTED]}"
      ;;
    "AMD_cpu_family6" )
      echo "${AMD_cpu_family6[$MODEL_DETECTED]}"
      ;;
    "AMD_cpu_family15" )
      echo "${AMD_cpu_family15[$MODEL_DETECTED]}"
      ;;
    "AMD_cpu_family16" )
      echo "${AMD_cpu_family16[$MODEL_DETECTED]}"
      ;;
    "AMD_cpu_family17" )
      echo "${AMD_cpu_family17[$MODEL_DETECTED]}"
      ;;
    "Intel_cpu_family5" )
      echo "${Intel_cpu_family5[$MODEL_DETECTED]}"
      ;;
    "Intel_cpu_family6" )
      echo "${Intel_cpu_family6[$MODEL_DETECTED]}"
      ;;
    "Intel_cpu_family15" )
      echo "${Intel_cpu_family15[$MODEL_DETECTED]}"
      ;;
    "Transmeta_cpu_family6" )
      echo "${Transmeta_cpu_family6[$MODEL_DETECTED]}"
      ;;
    "Transmeta_cpu_family15" )
      echo "${Transmeta_cpu_family15[$MODEL_DETECTED]}"
      ;;
    * )
      echo "NONE"
      ;;
  esac

}



# Return UTUTO's CPU type useful for choose a binary package repository
cpu_type_ututo () {

  case $1 in
    "AMD_cpu_family5" )
      echo "${UTUTO_AMD_cpu_family5[$MODEL_DETECTED]}"
      ;;
    "AMD_cpu_family6" )
      echo "${UTUTO_AMD_cpu_family6[$MODEL_DETECTED]}"
      ;;
    "AMD_cpu_family15" )
      echo "${UTUTO_AMD_cpu_family15[$MODEL_DETECTED]}"
      ;;
    "AMD_cpu_family16" )
      echo "${UTUTO_AMD_cpu_family16[$MODEL_DETECTED]}"
      ;;
    "AMD_cpu_family17" )
      echo "${UTUTO_AMD_cpu_family17[$MODEL_DETECTED]}"
      ;;
    "Intel_cpu_family5" )
      echo "${UTUTO_Intel_cpu_family5[$MODEL_DETECTED]}"
      ;;
    "Intel_cpu_family6" )
      echo "${UTUTO_Intel_cpu_family6[$MODEL_DETECTED]}"
      ;;
    "Intel_cpu_family15" )
      echo "${UTUTO_Intel_cpu_family15[$MODEL_DETECTED]}"
      ;;
    "Transmeta_cpu_family6" )
      echo "${UTUTO_Transmeta_cpu_family6[$MODEL_DETECTED]}"
      ;;
    "Transmeta_cpu_family15" )
      echo "${UTUTO_Transmeta_cpu_family15[$MODEL_DETECTED]}"
      ;;
    * )
      echo "NONE"
      ;;
  esac

}



# Return CPU type or UTUTO's cpu type.
case $OPTION in
  "march" )
    cpu_type "$family"
    ;;
  "march-ututo" )
    cpu_type_ututo "$family"
    ;;
  * )
    cpu_type "$family"
    ;;
esac

