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

#get the name of each fan in an array

SNMPTABLENAME=($(snmptable -v 2c -c $COMMUNITY -m ALL -CH -Cf , $HOSTNAME .1.3.6.1.2.1.47.1.1.1))

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

#get the name of each fan  Yes, I know, loops and this is kind of slow
#but it only takes 8 seconds, and my time "limit" is five minutes. So low priority.
#at some point, I'll do this as a table and process that, it'll be more flexible, but for now, this works.
#FAN1STATUSNAME="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.47.1.1.1.1.7.4|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN2STATUSNAME="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.47.1.1.1.1.7.5|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN3STATUSNAME="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.47.1.1.1.1.7.6|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN4STATUSNAME="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.47.1.1.1.1.7.7|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN5STATUSNAME="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.47.1.1.1.1.7.8|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN6STATUSNAME="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.47.1.1.1.1.7.9|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN7STATUSNAME="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.47.1.1.1.1.7.10|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN8STATUSNAME="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.47.1.1.1.1.7.11|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN9STATUSNAME="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.47.1.1.1.1.7.12|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN10STATUSNAME="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.47.1.1.1.1.7.13|awk 'BEGIN { FS=": "; } {print $2;}')"

#get the RPM of each fan in an array

SNMPTABLERPM=($(snmptable -v 2c -c $COMMUNITY -m ALL -CH -Cf , $HOSTNAME .1.3.6.1.2.1.99.1.1))

#iterate through SNMPTABLERPM. Assign the first column using commas as field separators to TESTVAR
#if TESTVAR is "rpm", then assign the 4th column to FANSTATUSRPM, and the 5th column to FANSTATUS
#note that FANSTATUSRPM uses "index" as it's index variable, hence the increment in the if statement
for i in "${!SNMPTABLERPM[@]}"; do
     TESTVAR="$(echo ${SNMPTABLERPM[i]}|cut -d',' -f1)"       
     if [ $TESTVAR == "rpm" ]
     then
          FANSTATUSRPM[index]="$(echo ${SNMPTABLERPM[i]}|cut -d',' -f4)"
          FANSTATUS[rpmindex]="$(echo ${SNMPTABLERPM[i]}|cut -d',' -f5)"
          ((index++))
     fi
done

#for i in "${!FANSTATUSRPM[@]}"; do
#
#     echo ${FANSTATUSRPM[i]}
#
#done

#FAN1STATUSRPM="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.4.4|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN2STATUSRPM="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.4.5|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN3STATUSRPM="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.4.6|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN4STATUSRPM="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.4.7|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN5STATUSRPM="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.4.8|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN6STATUSRPM="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.4.9|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN7STATUSRPM="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.4.10|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN8STATUSRPM="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.4.11|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN9STATUSRPM="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.4.12|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN10STATUSRPM="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.4.13|awk 'BEGIN { FS=": "; } {print $2;}')"

#get the status of each fan

#FAN1STATUS="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.5.4|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN2STATUS="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.5.5|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN3STATUS="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.5.6|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN4STATUS="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.5.7|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN5STATUS="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.5.8|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN6STATUS="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.5.9|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN7STATUS="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.5.10|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN8STATUS="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.5.11|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN9STATUS="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.5.12|awk 'BEGIN { FS=": "; } {print $2;}')"
#FAN10STATUS="$(snmpget -v 2c -c $COMMUNITY -m ALL -Ov $HOSTNAME .1.3.6.1.2.1.99.1.1.1.5.13|awk 'BEGIN { FS=": "; } {print $2;}')"

#concatenate the results into a single var

FANSTATUSRESULTS+="${FAN1STATUSNAME}: ${FAN1STATUSRPM}, ${FAN1STATUS}${NEWLINE}"
FANSTATUSRESULTS+="${FAN2STATUSNAME}: ${FAN2STATUSRPM}, ${FAN2STATUS}${NEWLINE}"
FANSTATUSRESULTS+="${FAN3STATUSNAME}: ${FAN3STATUSRPM}, ${FAN3STATUS}${NEWLINE}"
FANSTATUSRESULTS+="${FAN4STATUSNAME}: ${FAN4STATUSRPM}, ${FAN4STATUS}${NEWLINE}"
FANSTATUSRESULTS+="${FAN5STATUSNAME}: ${FAN5STATUSRPM}, ${FAN5STATUS}${NEWLINE}"
FANSTATUSRESULTS+="${FAN6STATUSNAME}: ${FAN6STATUSRPM}, ${FAN6STATUS}${NEWLINE}"
FANSTATUSRESULTS+="${FAN7STATUSNAME}: ${FAN7STATUSRPM}, ${FAN7STATUS}${NEWLINE}"
FANSTATUSRESULTS+="${FAN8STATUSNAME}: ${FAN8STATUSRPM}, ${FAN8STATUS}${NEWLINE}"
FANSTATUSRESULTS+="${FAN9STATUSNAME}: ${FAN9STATUSRPM}, ${FAN9STATUS}${NEWLINE}"
FANSTATUSRESULTS+="${FAN10STATUSNAME}: ${FAN10STATUSRPM}, ${FAN10STATUS}${NEWLINE}"

echo -e "${FANSTATUSRESULTS}"

