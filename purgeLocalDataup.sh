#!/bin/sh
#
## removes all sql.gz.gpg files older than the supplied number of days

threshold="$1"
if [ -z "$threshold" ];then
	echo '||&||must supply the number of days to retain||&||'
	exit 1
fi

echo '||&||'
find /home/risc/datafiles -type f -ctime +$threshold -name "*.sql.gz.gpg" | while read line;do
	## skip inventory uploads
	echo "$line" | grep 'inventory' &>/dev/null
	if [ $? -eq 0 ];then
		continue
	fi
	## show what we're removing
	echo `ls -lh "$line" | awk '{ print $6" "$7" "$8" "$9 }'`
	## remove it
	rm "$line"
done
echo '||&||'

