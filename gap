#!/bin/bash

Version=3.00
Myname="${0##*/}"

:<<'DOC'
= gap - report gaps, inversions, and repeats in numerical columns

= Synopsis
gap [options] filename	

== Options
-c,--column=INT		set column to INT; default: 1
-s,--separator=re	set column separator to Ruby regexp; default: tab
-f,--first		stop after reporting the first missing number
-h,--help		print this help and exit
-H,--Help		print full documentation via less and exit
-V,--version		print version and exit

= Description
gap inspects (supposedly sorted, decimal) numerical columns in tab-separated databases 
and reports missing numbers, duplications and inversions. Columns are counted starting at 1. 
gap can also read from standard input. Leading zeros are stripped from numbers before use.

= Options
Options are shown in the Synopsis section in logically identical pairs,
with the full version in the second column and the minimum shorthand
(without any parameters) in the first.
You can set option defaults in an alias. For example:

   alias gap='gap --separator=":"' 

--help	
	prints help information and exits
	
--Help	
	shows full documentation /via/ less, then exits
	
--version	
	prints name and version and then exits
	
--col=number	
	look for gaps in column |number|.
	
--separator=string	
	assume /string/ to be the column separator regular expression,
	instead of the default tab (|\t|). For example, to make any sequence
	of non-digit characters separate the columns: |--separator='[^[:digit:]]+/'|
	
--first	
	stop after reporting the first missing number of range

= Examples
With this input in file test:
        12:001
        12:002
        12:003
        13:006
        14:007
        14:008
        15:009
        26:010
        27:008
        27:009
        28:010
        29:11
        30:12
        31:13a
        32:14
        33:15
        34:
        35:17

here are some examples:
        $ gap -s: test
           4:   2 repeats of    12
           7:   1  repeat of    14
           8:  10    missing    16 .. 25
          11:   1  repeat of    27

        $ gap -s: -c2 test      
           4:   2    missing     4 .. 5
           9:   2       back    10 -> 8
          14:     bad number   13a using 13
          17:    empty field
          17:   1    missing    16

= Author
[Wybo Dekker](wybo@dekkerdocumenten.nl)

= Copyright
Released under the [GNU General Public License](www.gnu.org/copyleft/gpl.html)
DOC

Red='\e[38;5;1m'
    die() { local i; for i; do echo -e "$Myname: $Red$i"; done 1>&2; exit 1; }
helpsrt() { sed -n '/^= Synopsis/,/^= /p' "$0"|sed '1d;$d'; exit; }
helpall() { sed -n "/^:<<'DOC'$/,/^DOC/p" "$0"|sed '1d;$d'|
            less -P"$Myname-${Version/./·} (press h for help, q to quit)";exit; }

function repeat {
   test "$r" -gt 1 && op=s || op=
   printf "%4d: %3d %10s %5d\n" "$lineno" "$r" "repeat$op of" "$old"
   r=0
}

column=1 separator=$'\t' first=false
:<<'DOC' #----------------------------------------------------------------------
= handle_options
synopsis:	 handle_options "$@"
description:	handle the options.
globals used:	 Myname Version
globals  set:	 args
DOC
#-------------------------------------------------------------------------------
handle_options() {
   local options
   options=$(getopt \
      -n "$Myname" \
      -o c:s:fhHVI \
      -l column:,separator:,first,help,Help,version -- "$@"
   ) || exit 1
   eval set -- "$options"
   first=false
   while [ $# -gt 0 ]; do
      case $1 in
      (-h|--help)       helpsrt;;
      (-H|--Help)       helpall;;
      (-V|--version)    echo $Version; exit;;
      (-I)	        instscript "$0" ||
			   die 'the -I option is for developers only'
			exit
			;;
      (-c|--column)     column=$2
			shift 2
			;;
      (-s|--separator)	separator=$2
			shift 2
			;;
      (-f|--first)    	first=true
			shift
			;;
      (--) 		shift
			break
			;;
      (*)  		break
			;;
      esac
   done
   args=("$@")
}

handle_options "$@"
set -- "${args[@]}"

(( $# > 1 )) && die "expecting zero or 1 argument"
input=${1:-/dev/stdin}
[[ -e $input ]] || die "input file $input does not exist"
[[ -r $input ]] || die "input file $input not readable"
((column--))	# user col 1 is element 0 in array

lineno=1 r=0
while read -r line; do
   IFS=$separator read -ra a <<<"$line"
   if (( ${#a[@]}<=column )); then
      printf "%4d: %14s\n" $lineno "empty field"
      continue
   fi
   if [[ ${a[$column]} =~ ^(0*)([0-9]*)(.*)$ ]]; then
      number=${BASH_REMATCH[2]}
      err=${BASH_REMATCH[3]}
   else
      number=''
      err=''
   fi
   if [[ -n $err ]]; then 
      printf "%4d: %14s %5s using %s\n" \
	 $lineno 'bad number' "${a[$column]}" "$number"
      [[ -n $number ]] || continue
   fi
   nb=$((number - 1))
   : "${old:=$nb}"
   inc=$((number - old))
   if (( inc > 2 )); then
      (( r > 0 )) && repeat
      printf "%4d: %3d %10s %5d .. %d\n" \
           $lineno $((inc-1)) missing $((old+1)) $((inc+old-1))
      $first && exit
   elif (( inc > 1 )); then
      test $r -gt 0 && repeat
      printf "%4d: %3d %10s %5s\n" $lineno $((inc-1)) missing $((old+1))
      $first && exit
   elif (( inc < 0 )); then
      printf "%4d: %3s %10s %5s -> %s\n" \
	 $lineno $((old-number)) back $old "$number"
   elif (( inc == 0 )); then
      ((r+=1))
   else
      (( r > 0 )) && repeat
      r=0
   fi
   old=$number
   ((lineno+=1))
done < "$input"
# in case the last one was repeating:
(( r > 0 )) && repeat
