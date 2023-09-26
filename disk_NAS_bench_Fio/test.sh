#!/bin/bash
#############################################################################################################
#Changelog                                                                                                  #
#############################################################################################################
#Added prompts for user input to configure script instead of relying on hardcoded settings.
#Added a lot of errorchecking
#The script is now optionally compatible with dash (this is the reason for there being a sed command at the end of every echo -e instance, dash liked to print the -e part when I was testing.)
#Vastly improved compatibility across distributions
#Special thanks to everyone who contributed here: https://gist.github.com/i3v/99f8ef6c757a5b8e9046b8a47f3a9d5b
#Also extra special thanks to BAGELreflex on github for this: https://gist.github.com/BAGELreflex/c04e7a25d64e989cbd9376a9134b8f6d it made a huge difference to this improved version.
#Added optimizations for 512k and 4k tests (they now use QSIZE instead of SIZE, it makes these tests a lot faster and doesn't affect accuracy much, assuming SIZE is appropriately configured for your drive.)
#Added option to not use legacy (512k and Q1T1 Seq R/W tests) to save time when testing.
#Ensured the script can run fine without df installed now. Some information may be missing but worst case scenario it'll just look ugly.
#Added a save results option that imitates the saved results from crystaldiskmark; the formatting is a little wonky but it checks out. Great for comparing results between operating systems.
#Reconfigured results to use MegaBytes instead of MebiBytes (This is what crystaldiskmark uses so results should now be marginally closer).
#Sequential read/write results (512k, q1t1 seq and q32t1 seq) will now appear as soon as they're finished and can be viewed while the 4k tests are running.
#Note: The legacy test option defaults to no if nothing is selected, the result saving defaults to yes. It's easy to change if you don't like this.
#Observation: When testing, I observed that the read results seemed mostly consistent with the results I got from crystaldiskmark on windows, however there's something off with the write results.
#Sorry for the messy code :)
#############################################################################################################
#User input requests and error checking                                                                     #
#############################################################################################################
if [ -f /usr/bin/fio ]; then #Dependency check
    :
else
    echo -e "\033[1;31mError: This script requires fio to run, please make sure it is installed." | sed 's:-e::g'
    exit
fi

if [ -f /usr/bin/df ]; then #Dependency check
    nodf=0
else
    nodf=1
    echo -e "\033[1;31mWarning: df is not installed, this script relies on df to display certain information, some information may be missing." | sed 's:-e::g'
fi

if [ "$(ps -ocmd= | tail -1)" = "bash" ]; then
    echo "What drive do you want to test? (Default: $HOME on /dev/$(df $HOME | grep /dev | cut -d/ -f3 | cut -d" " -f1) )"
    echo -e "\033[0;33mOnly directory paths (e.g. /home/user/) are valid targets.\033[0;00m"
    read -e TARGET
else #no autocomplete available for dash.
    echo "What drive do you want to test? (Default: $HOME on /dev/$(df $HOME | grep /dev | cut -d/ -f3 | cut -d" " -f1) )"
    echo -e "\033[0;33mOnly directory paths (e.g. /home/user/) are valid targets. Use bash if you want autocomplete.\033[0;00m" | sed 's:-e::g'
    read TARGET
fi

echo "
How many times to run the test? (Default: 5)"
read LOOPS

echo "How large should each test be in MiB? (Default: 1024)"
echo -e "\033[0;33mOnly multiples of 32 are permitted!\033[0;00m" | sed 's:-e::g'

read SIZE

echo "Do you want to write only zeroes to your test files to imitate dd benchmarks? (Default: 0)"
echo -e "\033[0;33mEnabling this setting may drastically alter your results, not recommended unless you know what you're doing.\033[0;00m" | sed 's:-e::g'
read WRITEZERO

echo "Would you like to include legacy tests (512kb & Q1T1 Sequential Read/Write)? [Y/N]"
read LEGACY

if [ -z $TARGET ]; then
    TARGET=$HOME
elif [ -d $TARGET ]; then
    :
else
    echo -e "\033[1;31mError: $TARGET is not a valid path."
    exit
fi

if [ -z $LOOPS ]; then
    LOOPS=5
elif [ "$LOOPS" -eq "$LOOPS" ] 2>/dev/null; then
    :
else
  echo -e "\033[1;31mError: $LOOPS is not a valid number, please use a number to declare how many times to loop tests." | sed 's:-e::g'
  exit
fi

if [ -z $SIZE ]; then
    SIZE=1024
elif [ "$SIZE" -eq "$SIZE" ] 2>/dev/null && ! (( $SIZE % 32 )) 2>/dev/null;then
    :
else
    echo -e "\033[1;31mError: The test size must be an integer set to a multiple of 32. Please write a multiple of 32 for the size setting (Optimal settings: 1024, 2048, 4096, 8192, 16384)."
    exit
fi

if [ -z $WRITEZERO ]; then
    WRITEZERO=0
elif [ "$WRITEZERO" -eq 1 ] 2>/dev/null || [ "$WRITEZERO" -eq 0 ] 2>/dev/null; then
    :
else
    echo -e "\033[1;31mError: WRITEZERO only accepts 0 or 1, $WRITEZERO is not a valid argument." | sed 's:-e::g'
    exit
fi

if [ "$LEGACY" = "Y" ] || [ "$LEGACY" = "y" ]; then
    :
else
    LEGACY=no
fi

if [ $nodf = 1 ]; then
    echo "
    Settings are as follows:
    Target Directory: $TARGET
    Size Of Test: $SIZE MiB
    Number Of Loops: $LOOPS
    Write Zeroes: $WRITEZERO
    Legacy Tests: $LEGACY
    "
    echo "Are you sure these are correct? [Y/N]"
    read REPLY
    if [ $REPLY = Y ] || [ $REPLY = y ]; then
        REPLY=""
    else
        echo ""
        exit
    fi

else
    DRIVE=$(df $TARGET | grep /dev | cut -d/ -f3 | cut -d" " -f1 | rev | cut -c 2- | rev)

    if [ "$(echo $DRIVE | cut -c -4)" = "nvme" ]; then #NVME Compatibility
        echo $DRIVE
        DRIVE=$(df $TARGET | grep /dev | cut -d/ -f3 | cut -d" " -f1 | rev | cut -c 3- | rev)
        echo $DRIVE
    fi
    DRIVEMODEL=$(cat /sys/block/$DRIVE/device/model | sed 's/ *$//g')
    DRIVESIZE=$(($(cat /sys/block/$DRIVE/size)*512/1024/1024/1024))GB
    DRIVEPERCENT=$(df -h $TARGET | cut -d ' ' -f11 | tail -n 1)
    DRIVEUSED=$(df -h $TARGET | cut -d ' ' -f6 | tail -n 1)

    echo "
    Settings are as follows:
    Target Directory: $TARGET
    Target Drive: $DRIVE
    Size Of Test: $SIZE MiB
    Number Of Loops: $LOOPS
    Write Zeroes: $WRITEZERO
    Legacy Tests: $LEGACY
    "
    echo "Are you sure these are correct? [Y/N]"
    read REPLY
    if [ "$REPLY" = "Y" ] || [ "$REPLY" = "y" ]; then
        REPLY=""
    else
        echo ""
        exit
    fi
fi
#############################################################################################################
#Setting the last Variables And Running Sequential R/W Benchmarks                                           #
#############################################################################################################


QSIZE=$(($SIZE / 32)) #Size of Q32Seq tests
SIZE=$(echo $SIZE)m
QSIZE=$(echo $QSIZE)m

if [ $nodf = 1 ]; then
    echo "
Running Benchmark,  please wait...
    "
else
    echo "
Running Benchmark on: /dev/$DRIVE, $DRIVEMODEL ($DRIVESIZE), please wait...
"
fi

if [ $LEGACY = Y ] || [ $LEGACY = y ]; then
    fio --loops=$LOOPS --size=$SIZE --filename="$TARGET/.fiomark.tmp" --stonewall --ioengine=libaio --direct=1 --zero_buffers=$WRITEZERO --output-format=json \
  --name=Bufread --loops=1 --bs=$SIZE --iodepth=1 --numjobs=1 --rw=readwrite \
  --name=Seqread --bs=$SIZE --iodepth=1 --numjobs=1 --rw=read \
  --name=Seqwrite --bs=$SIZE --iodepth=1 --numjobs=1 --rw=write \
  --name=SeqQ32T1read --bs=$QSIZE --iodepth=32 --numjobs=1 --rw=read \
  --name=SeqQ32T1write --bs=$QSIZE --iodepth=32 --numjobs=1 --rw=write \
  > "$TARGET/.fiomark.txt"

    fio --loops=$LOOPS --size=$QSIZE --filename="$TARGET/.fiomark-512k.tmp" --stonewall --ioengine=libaio --direct=1 --zero_buffers=$WRITEZERO --output-format=json \
  --name=512kread --bs=512k --iodepth=1 --numjobs=1 --rw=read \
  --name=512kwrite --bs=512k --iodepth=1 --numjobs=1 --rw=write \
  > "$TARGET/.fiomark-512k.txt"

    SEQR="$(($(cat "$TARGET/.fiomark.txt" | grep -A15 '"name" : "Seqread"' | grep bw | grep -v '_' | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/.fiomark.txt" | grep -A15 '"name" : "Seqread"' | grep -m1 iops | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
    SEQW="$(($(cat "$TARGET/.fiomark.txt" | grep -A80 '"name" : "Seqwrite"' | grep bw | grep -v '_' | sed 2\!d | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/.fiomark.txt" | grep -A80 '"name" : "Seqwrite"' | grep iops | sed '7!d' | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
    F12KR="$(($(cat "$TARGET/.fiomark-512k.txt" | grep -A15 '"name" : "512kread"' | grep bw | grep -v '_' | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/.fiomark-512k.txt" | grep -A15 '"name" : "512kread"' | grep -m1 iops | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
    F12KW="$(($(cat "$TARGET/.fiomark-512k.txt" | grep -A80 '"name" : "512kwrite"' | grep bw | grep -v '_' | sed 2\!d | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/.fiomark-512k.txt" | grep -A80 '"name" : "512kwrite"' | grep iops | sed '7!d' | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
    SEQ32R="$(($(cat "$TARGET/.fiomark.txt" | grep -A15 '"name" : "SeqQ32T1read"' | grep bw | grep -v '_' | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/.fiomark.txt" | grep -A15 '"name" : "SeqQ32T1read"' | grep -m1 iops | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
    SEQ32W="$(($(cat "$TARGET/.fiomark.txt" | grep -A80 '"name" : "SeqQ32T1write"' | grep bw | grep -v '_' | sed 2\!d | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/.fiomark.txt" | grep -A80 '"name" : "SeqQ32T1write"' | grep iops | sed '7!d' | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"

    echo -e "
Results:
\033[0;33m
Sequential Read: $SEQR
Sequential Write: $SEQW
\033[0;32m
512KB Read: $F12KR
512KB Write: $F12KW
\033[1;36m
Sequential Q32T1 Read: $SEQ32R
Sequential Q32T1 Write: $SEQ32W" | sed 's:-e::g'

else
    fio --loops=$LOOPS --size=$SIZE --filename="$TARGET/.fiomark.tmp" --stonewall --ioengine=libaio --direct=1 --zero_buffers=$WRITEZERO --output-format=json \
  --name=Bufread --loops=1 --bs=$SIZE --iodepth=1 --numjobs=1 --rw=readwrite \
  --name=SeqQ32T1read --bs=$QSIZE --iodepth=32 --numjobs=1 --rw=read \
  --name=SeqQ32T1write --bs=$QSIZE --iodepth=32 --numjobs=1 --rw=write \
  > "$TARGET/.fiomark.txt"

    SEQ32R="$(($(cat "$TARGET/.fiomark.txt" | grep -A15 '"name" : "SeqQ32T1read"' | grep bw | grep -v '_' | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/.fiomark.txt" | grep -A15 '"name" : "SeqQ32T1read"' | grep -m1 iops | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
    SEQ32W="$(($(cat "$TARGET/.fiomark.txt" | grep -A80 '"name" : "SeqQ32T1write"' | grep bw | grep -v '_' | sed 2\!d | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/.fiomark.txt" | grep -A80 '"name" : "SeqQ32T1write"' | grep iops | sed '7!d' | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"

    echo -e "
Results:
\033[1;36m
Sequential Q32T1 Read: $SEQ32R
Sequential Q32T1 Write: $SEQ32W" | sed 's:-e::g'
fi

#############################################################################################################
#4KiB Tests & Results                                                                                       #
#############################################################################################################

fio --loops=$LOOPS --size=$QSIZE --filename="$TARGET/.fiomark-4k.tmp" --stonewall --ioengine=libaio --direct=1 --zero_buffers=$WRITEZERO --output-format=json \
  --name=4kread --bs=4k --iodepth=1 --numjobs=1 --rw=randread \
  --name=4kwrite --bs=4k --iodepth=1 --numjobs=1 --rw=randwrite \
  --name=4kQ32T1read --bs=4k --iodepth=32 --numjobs=1 --rw=randread \
  --name=4kQ32T1write --bs=4k --iodepth=32 --numjobs=1 --rw=randwrite \
  --name=4kQ8T8read --bs=4k --iodepth=8 --numjobs=8 --rw=randread \
  --name=4kQ8T8write --bs=4k --iodepth=8 --numjobs=8 --rw=randwrite \
  > "$TARGET/.fiomark-4k.txt"

FKR="$(($(cat "$TARGET/.fiomark-4k.txt" | grep -A15 '"name" : "4kread"' | grep bw | grep -v '_' | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/.fiomark-4k.txt" | grep -A15 '"name" : "4kread"' | grep -m1 iops | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
FKW="$(($(cat "$TARGET/.fiomark-4k.txt" | grep -A80 '"name" : "4kwrite"' | grep bw | grep -v '_' | sed 2\!d | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/.fiomark-4k.txt" | grep -A80 '"name" : "4kwrite"' | grep iops | sed '7!d' | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
FK32R="$(($(cat "$TARGET/.fiomark-4k.txt" | grep -A15 '"name" : "4kQ32T1read"' | grep bw | grep -v '_' | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/.fiomark-4k.txt" | grep -A15 '"name" : "4kQ32T1read"' | grep -m1 iops | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
FK32W="$(($(cat "$TARGET/.fiomark-4k.txt" | grep -A80 '"name" : "4kQ32T1write"' | grep bw | grep -v '_' | sed 2\!d | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/.fiomark-4k.txt" | grep -A80 '"name" : "4kQ32T1write"' | grep iops | sed '7!d' | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
FK8R="$(($(cat "$TARGET/.fiomark-4k.txt" | grep -A15 '"name" : "4kQ8T8read"' | grep bw | grep -v '_' | sed 's/        "bw" : //g' | sed 's:,::g' | awk '{ SUM += $1} END { print SUM }')/1000))MB/s [   $(cat "$TARGET/.fiomark-4k.txt" | grep -A15 '"name" : "4kQ8T8read"' | grep iops | sed 's/        "iops" : //g' | sed 's:,::g' | awk '{ SUM += $1} END { print SUM }' | cut -d. -f1) IOPS]"
FK8W="$(($(cat "$TARGET/.fiomark-4k.txt" | grep -A80 '"name" : "4kQ8T8write"' | grep bw | sed 's/        "bw" : //g' | sed 's:,::g' | awk '{ SUM += $1} END { print SUM }')/1000))MB/s [   $(cat "$TARGET/.fiomark-4k.txt" | grep -A80 '"name" : "4kQ8T8write"' | grep '"iops" '| sed 's/        "iops" : //g' | sed 's:,::g' | awk '{ SUM += $1} END { print SUM }' | cut -d. -f1) IOPS]"

echo -e "\033[1;35m
4KB Q8T8 Read: $FK8R
4KB Q8T8 Write: $FK8W
\033[1;33m
4KB Q32T1 Read: $FK32R
4KB Q32T1 Write: $FK32W
\033[0;36m
4KB Read: $FKR
4KB Write: $FKW
\033[0m
" | sed 's:-e::g'

echo "Would you like to save these results? [Y/N]"
read REPLY
if [ "$REPLY" = "N" ] || [ "$REPLY" = "n" ]; then
    REPLY=""
else
    DRIVESIZE=$(df -h $TARGET | cut -d ' ' -f3 | tail -n 1)
    echo "
Saving at $HOME/$DRIVE$(date +%F%I%M%S).txt
"
    if [ "$LEGACY" = "Y" ] || [ "$LEGACY" = "y" ]; then
echo "-----------------------------------------------------------------------
Flexible I/O Tester - $(fio --version) (C) axboe
                          Fio Github : https://github.com/axboe/fio
                       Script Source : https://unix.stackexchange.com/a/480191/72554
-----------------------------------------------------------------------
* MB/s = 1,000,000 bytes/s
* KB = 1000 bytes, KiB = 1024 bytes

   Legacy Seq Read (Q=  1,T= 1) :   $SEQR
  Legacy Seq Write (Q=  1,T= 1) :   $SEQW
   512KiB Seq Read (Q=  1,T= 1) :   $F12KR
  512KiB Seq Write (Q=  1,T= 1) :   $F12KW
   Sequential Read (Q= 32,T= 1) :   $SEQ32R
  Sequential Write (Q= 32,T= 1) :   $SEQ32W
  Random Read 4KiB (Q=  8,T= 8) :   $FK8R
 Random Write 4KiB (Q=  8,T= 8) :   $FK8W
  Random Read 4KiB (Q= 32,T= 1) :   $FK32R
 Random Write 4KiB (Q= 32,T= 1) :   $FK32W
  Random Read 4KiB (Q=  1,T= 1) :   $FKR
 Random Write 4KiB (Q=  1,T= 1) :   $FKW

  Test : $(echo $SIZE | rev | cut -c 2- | rev) MiB [$DRIVEMODEL, $DRIVE $DRIVEPERCENT ($(echo $DRIVEUSED | rev | cut -c 2- | rev)/$(echo $DRIVESIZE | rev | cut -c 2- | rev) GiB] (x$LOOPS)  [Interval=0 sec]
  Date : $(date +%F | sed 's:-:/:g') $(date +%T)
    OS : $(uname -srm)
  " > "$HOME/$DRIVE$(date +%F%I%M%S).txt"
    else
echo "-----------------------------------------------------------------------
Flexible I/O Tester - $(fio --version) (C) axboe
                          Fio Github : https://github.com/axboe/fio
                       Script Source : https://unix.stackexchange.com/a/480191/72554
-----------------------------------------------------------------------
* MB/s = 1,000,000 bytes/s
* KB = 1000 bytes, KiB = 1024 bytes

   Sequential Read (Q= 32,T= 1) :   $SEQ32R
  Sequential Write (Q= 32,T= 1) :   $SEQ32W
  Random Read 4KiB (Q=  8,T= 8) :   $FK8R
 Random Write 4KiB (Q=  8,T= 8) :   $FK8W
  Random Read 4KiB (Q= 32,T= 1) :   $FK32R
 Random Write 4KiB (Q= 32,T= 1) :   $FK32W
  Random Read 4KiB (Q=  1,T= 1) :   $FKR
 Random Write 4KiB (Q=  1,T= 1) :   $FKW

  Test : $(echo $SIZE | rev | cut -c 2- | rev) MiB [$DRIVEMODEL, $DRIVE $DRIVEPERCENT ($(echo $DRIVEUSED | rev | cut -c 2- | rev)/$(echo $DRIVESIZE | rev | cut -c 2- | rev) GiB] (x$LOOPS)  [Interval=0 sec]
  Date : $(date +%F | sed 's:-:/:g') $(date +%T)
    OS : $(uname -srm)
  " > "$HOME/$DRIVE$(date +%F%I%M%S).txt"
    fi
fi


rm "$TARGET/.fiomark.txt" "$TARGET/.fiomark-512k.txt" "$TARGET/.fiomark-4k.txt" 2>/dev/null
rm "$TARGET/.fiomark.tmp" "$TARGET/.fiomark-512k.tmp" "$TARGET/.fiomark-4k.tmp" 2>/dev/null
