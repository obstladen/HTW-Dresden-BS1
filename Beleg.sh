#!/bin/bash

#Ueberpruefung der Kommandozeilenparamter

if [ $# = 0 ]
then
	echo "Sie haben kein Kommandozeilenparamter angegeben"
	echo "moeglich waeren: stat, check , search"
	exit 1
elif [ $# = 1 ]
then
	if [ $1 != "check" -a $1 != "stat"  ]
	then
		echo "Bitte ueberpruefen Sie ihre Eingabe"
		echo "moeglich waeren: stat, check , search"
                echo "Bei search: enteder eine Zeitspanne oder ein Autor angeben"

		exit 2
	fi
elif [ $# = 2 ]
then
	if [ $1 != "search" ]
	then
		echo "Bitte uberpruefen Sie ihre Eingabe"
		echo "Bei search: enteder eine Zeitspanne oder ein Autor angeben"
	       exit 3
       fi
       if [[ "$2" =~ ^[0-9]{1,4}-[0-9]{1,4} ]]
       then
		jahr1=${2:0:4}
        	jahr2=${2:5:4}
        	jahr=1
		date=`date +'%Y'`
        	if [ $jahr1 -eq $jahr2 -o $jahr1 -gt $jahr2 -o $jahr1 -lt 1900 -o $jahr2 -gt $date ]
        	then
                	echo "Bitte geben Sie eine korrekte Zeitspanne ein"
                	exit 4
        	fi
	elif [[ "$2" =~ ^[[:alpha:]]+ ]]
        then
                name=$2
		jahr=0
        else
                echo "Bitte ueberpruefen Sie ihre Eingabe"
                exit 5
	fi
fi
# Uberpruefung ob Literaturdatenbank vorhanden und lesbar ist

if [ -r literatur.bib ]
then
	datei=literatur.bib
else
	echo "Literaturdatenbank ist nicht vorhanden"
	exit 6
fi

if [[ "$1" = "check" ]]	
then
#Check Title
	echo""
	echo "title-Zeilen, welche nicht mit \"\{ beginnen"
	grep -F -n "title" "$datei" | grep -v "\"{*" | grep -v "booktitle"

# Check Jahreszahlen
	echo ""
	echo "Jahreszahlen, welche nicht zwischen 1900 und 2019 liegen"
	grep -E -n "year[[:space:]]=" "$datei" | grep -E -v "(19[0-9][0-9]|20[0-1][0-9])"

#check Zeilenlänge
	echo ""
	echo "Zeilen, welche mehr als 80 zeichen haben"
	grep -E -n ".{80,}" "$datei"

# Check Zitierschlüssel
	echo ""
	echo "Zeilen, ohne korrekten Zitierschluessel"
	grep -E -n "@[[:alpha:]]+\{" "$datei" | grep -E -v "[[:alpha:]]+-?[[:alpha:]]*:(19[0-9][0-9]|20[0-1][0-9]|xxxx):([[:alnum:]]+-*[[:alnum:]]*)"
fi

if [[ $1 = "stat" ]]
	then
# Anzahl Eintraege Insgesamt

	anzahl=$(grep -E -c "@[[:alpha:]]+" "$datei")
	echo ""
	echo "Es befinden sich $anzahl Eintraege in der Datenbank"

#Anzahl Eintraege pro Kategorie
	echo ""
	kategorie=( $( grep -E -o "@[[:alpha:]]+" "$datei" | sort | uniq  ))
	for i in ${!kategorie[@]}
	do
     		echo "Anzahl Eintraege in ${kategorie[$i]}"
		grep -c -e "${kategorie[$i]}" "$datei"
	done

# Anzahl Eintraege pro Jahr
	echo ""
	echo "Anzahl Eintraege pro Jahr"
	grep -E "year[[:space:]]=" "$datei" | grep -E -o "(19[0-9][0-9]|20[0-1][0-9])" | sort | uniq -c
fi

#search
if [[ $1 = "search" ]]
then
#Filterung nach dem angegebenen Zeitraum
	if [[ $jahr = "1" ]]
	then
		i=0
		zeitspanne=$((jahr2-jahr1)) 
 		while [ $i -le $zeitspanne ]
		do
		#mehree Zeilem?
		sed -E -n "/@[[:alpha:]]+\{[[:alpha:]]+-?[[:alpha:]]*:$jahr1.*/,/^\}/p" "$datei" 
		#grep -E  "@[[:alpha:]]+\{[[:alpha:]]+-?[[:alpha:]]*:$jahr1" "$datei"
		if [[ $? == 0 ]]
		then
			treffer=1
		fi
			i=$((i+1))
			jahr1=$((jahr1+1))
		done
		if [[ $treffer != 1 ]]
		then
			echo "kein Treffer"
			exit 7
		fi
#Suche nach Autor
	elif [[ $jahr = 0 ]]
	then
		if !	sed -E -n "/@[[:alpha:]]+\{$name:/,/^\}/p" "$datei"
		then
			echo "kein Treffer" 
			exit 8
		fi	
	fi
fi
exit 0
