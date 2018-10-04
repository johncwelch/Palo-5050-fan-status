#!/bin/bash

#this gets the name, rpm, and status of all the fans in the palo 5050s

#clear the getopts OPTIND
OPTIND=1

#set up TESTVAR
TESTVAR=""

#make newline a variable to make life easier

NEWLINE='\n'

#set up array vars

declare -a SNMPTABLERPM #raw snmptable return
declare -a FANSTATUSRPM #for individual RPM values
declare -a FANSTATUS #for actual fan status, ok or not okay
declare -a SNMPTABLENAME #snmptable return for name
declare -a FANSTATUSNAME #for indvidual names

#set up array start for FANSTATUSRPM
declare -i index
index=0

#set up array start for FANSTATUSNAME
declare -i nameindex
nameindex=0

#set up final output var

FANSTATUSRESULTS=""

#parse options
while getopts "H:c:" option
     do
          case "${option}" in

          H) HOSTNAME=$OPTARG;;

          c) COMMUNITY=$OPTARG;;

          :) echo "Usage - palofanstatus.sh -H <hostname> -c <SNMP v2c Community string> BOTH flags are required" >&2
          exit 1
          ;;

          esac
     done

#set the input field separator to newline, this avoids problems with spaces in the snmptable return
IFS=$'\n'

#get the RPM and status of each fan in an array
SNMPTABLERPM=($(snmptable -v 2c -c $COMMUNITY -m ALL -CH -Cf , $HOSTNAME .1.3.6.1.2.1.99.1.1))

#get the name of each fan in an array
SNMPTABLENAME=($(snmptable -v 2c -c $COMMUNITY -m ALL -CH -Cf , $HOSTNAME .1.3.6.1.2.1.47.1.1.1))

#iterate through SNMPTABLENAME, grab the name of each fan
for i in "${!SNMPTABLENAME[@]}"; do
     TESTVAR="$(echo ${SNMPTABLENAME[i]}|cut -d',' -f1)"
     if [[ ${TESTVAR} != Fan* ]]
     then
          continue
     else
          FANSTATUSNAME[nameindex]=$TESTVAR
          ((nameindex++))
     fi
done

#iterate through SNMPTABLERPM. Assign the first column using commas as field separators to TESTVAR
#if TESTVAR is "rpm", then assign the 4th column to FANSTATUSRPM and the 5th column to FANSTATUS
#note that FANSTATUSRPM uses "index" as it's index variable, hence the increment in the if statement
for i in "${!SNMPTABLERPM[@]}"; do
     TESTVAR="$(echo ${SNMPTABLERPM[i]}|cut -d',' -f1)"       
     if [ $TESTVAR == "rpm" ]
     then
          FANSTATUSRPM[rpmindex]="$(echo ${SNMPTABLERPM[i]}|cut -d',' -f4)"
          FANSTATUS[rpmindex]="$(echo ${SNMPTABLERPM[i]}|cut -d',' -f5)"
          ((rpmindex++))
     fi
done

#build FANSTATUSRESULTS
for i in "${!FANSTATUSRPM[@]}"; do
     FANSTATUSRESULTS+="${FANSTATUSNAME[i]}: ${FANSTATUSRPM[i]}, ${FANSTATUS[i]}\n"

done

#and here's our output
echo -e "${FANSTATUSRESULTS}"