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
declare -a FANSTATUSRESULTS #use an array for this, makes for neater output

#set up array start for FANSTATUSRPM
declare -i index
index=0

#set up array start for FANSTATUSNAME
declare -i nameindex
nameindex=0

#parse options
while getopts "H:c:h:" option
     do
          case "${option}" in

          H) HOSTNAME=$OPTARG;;

          c) COMMUNITY=$OPTARG;;
          
          h) echo "Usage - palofanstatus.sh -H <hostname> -c <SNMP v2c Community string> BOTH flags are required" >&2
          exit 1
          ;;

          \?) echo "Invalid option: -$OPTARG Usage - palofanstatus.sh -H <hostname> -c <SNMP v2c Community string> BOTH flags are required" >&2
          exit 1
          ;;

          ?) echo "Invalid option: -$OPTARG Usage - palofanstatus.sh -H <hostname> -c <SNMP v2c Community string> BOTH flags are required" >&2
          exit 1
          ;;

          :) echo "Option -$OPTARG requires a parameter. Usage - palofanstatus.sh -H <hostname> -c <SNMP v2c Community string> BOTH flags are required" >&2
          exit 1
          ;;

          *) echo "Invalid option: -$OPTARG Usage - palofanstatus.sh -H <hostname> -c <SNMP v2c Community string> BOTH flags are required" >&2
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
      FANSTATUSRESULTS[i]="${FANSTATUSNAME[i]}: ${FANSTATUSRPM[i]}, ${FANSTATUS[i]};"
done

#build the data output string for nagios

FANSTATUSOUTPUT="" #initialize this

#and here's our output, built the nagios way
for i in "${FANSTATUSRESULTS[@]}"; do
     FANSTATUSOUTPUT+=$i"\n"
done

#remove trailing \n by yanking last two characters. 
FANSTATUSOUTPUT=${FANSTATUSOUTPUT%??}

#glom pipe char onto end of FANSTATUSOUTPUT, needed to separate human output from service perf data

FANSTATUSOUTPUT+="|"
#echo -e $FANSTATUSOUTPUT

fsresultsindex=1 #this is a numerical label to match how the fans are counted in the palos

#build perfdata string

FANSTATUSPERFDATA=""
for i in "${FANSTATUSRPM[@]}"; do
     FANSTATUSPERFDATA+="'Fan $fsresultsindex'="$i" "
    ((fsresultsindex++))
done

#trim trailing space from FANSTATUSPERFDATA
FANSTATUSPERFDATA=${FANSTATUSPERFDATA%?}

#build final output string
FANSTATUSOUTPUT+=$FANSTATUSPERFDATA

#output the fan data with perfdata
echo -e $FANSTATUSOUTPUT

#we're ALWAYS FINE, even when we aren't. One day, I'll get clever here. Don't hold your breath.
exit 0