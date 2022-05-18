#!/bin/bash
echo "info from proc"
echo PID $'\t' STATE $'\t'$'\t' TIME $'\t' COMMAND
echo --------  ------------  $'\t' ---  $'\t' ------------
for valpid in /proc/[0-9]*
do

pid=$(cat $valpid/status | grep Pid | awk '(NR == 1)' | cut -f2 -d ":" | cut -f2)

stat=$(cat $valpid/status | awk '(NR == 3)' | cut -f2 -d ":" | cut -f2 | sed "s/${pid}/"Z"/g")

PROCESS_STAT=$(sed -E 's/\([^)]+\)/X/' "/proc/$pid/stat")
PROCESS_UTIME=$(cat /proc/$pid/stat | awk '{print $13}')
PROCESS_STIME=$(cat /proc/$pid/stat | awk '{print $14}')
PROCESS_STARTTIME=$(cat /proc/$pid/stat | awk '{print $21}')
SYSTEM_UPTIME_SEC=$(tr . ' ' </proc/uptime | awk '{print $1}')
CLK_TCK=$(getconf CLK_TCK)
	let PROCESS_UTIME_SEC="$PROCESS_UTIME / $CLK_TCK"
	let PROCESS_STIME_SEC="$PROCESS_STIME / $CLK_TCK"
	let PROCESS_USAGE_SEC="$PROCESS_UTIME_SEC + $PROCESS_STIME_SEC"

name=$(cat $valpid/status | awk '(NR == 1)' | cut -f2 -d ":" | cut -f2)

echo "${pid}" $'\t' "${stat}" $'\t' "${PROCESS_USAGE_SEC}s" $'\t' "${name}"
done
