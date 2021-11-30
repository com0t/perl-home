/usr/bin/perl /home/risc/stopAllPerf.pl
sleep 5
pkill -f ITGSend
mysql -urisc -prisc RISC_Discovery -e "delete from cmdcontrol"
pkill -f perl