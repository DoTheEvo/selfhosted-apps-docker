#!/bin/bash

# this script requires fio bc jq
type fio bc jq > /dev/null || exit

# Directory to test
TEST_DIR=$1

# Parameters for the tests should be representive of the workload you want to simulate
BS="1M"             # Block size
IOENGINE="libaio"   # IO engine
IODEPTH="16"        # IO depth sets how many I/O requests a single job can handle at once
DIRECT="1"          # Direct IO at 0 is buffered with RAM which may skew results and I/O 1 is unbuffered
NUMJOBS="5"         # Number of jobs is how many independent I/O streams are being sent to the storage
FSYNC="0"           # Fsync 0 leaves flushing up to Linux 1 force write commits to disk
NUMFILES="5"        # Number of files is number of independent I/O threads or processes that FIO will spawn
FILESIZE="1G"       # File size for the tests, you can use: K M G

# Check if directory is provided
if [ -z "$TEST_DIR" ]; then
    echo "Usage: $0 [directory]"
    exit 1
fi

# Function to perform FIO test and display average output
perform_test() {
    RW_TYPE=$1

    echo "Running $RW_TYPE test with block size $BS, ioengine $IOENGINE, iodepth $IODEPTH, direct $DIRECT, numjobs $NUMJOBS, fsync $FSYNC, using $NUMFILES files of size $FILESIZE on $TEST_DIR"

    # Initialize variables to store cumulative values
    TOTAL_READ_IOPS=0
    TOTAL_WRITE_IOPS=0
    TOTAL_READ_BW=0
    TOTAL_WRITE_BW=0

    for ((i=1; i<=NUMFILES; i++)); do
        TEST_FILE="$TEST_DIR/fio_test_file_$i"

        # Running FIO for each file and parsing output
        OUTPUT=$(fio --name=test_$i \
                     --filename=$TEST_FILE \
                     --rw=$RW_TYPE \
                     --bs=$BS \
                     --ioengine=$IOENGINE \
                     --iodepth=$IODEPTH \
                     --direct=$DIRECT \
                     --numjobs=$NUMJOBS \
                     --fsync=$FSYNC \
                     --size=$FILESIZE \
                     --group_reporting \
                     --output-format=json)

        # Accumulate values
        TOTAL_READ_IOPS=$(echo $OUTPUT | jq '.jobs[0].read.iops + '"$TOTAL_READ_IOPS")
        TOTAL_WRITE_IOPS=$(echo $OUTPUT | jq '.jobs[0].write.iops + '"$TOTAL_WRITE_IOPS")
        TOTAL_READ_BW=$(echo $OUTPUT | jq '(.jobs[0].read.bw / 1024) + '"$TOTAL_READ_BW")
        TOTAL_WRITE_BW=$(echo $OUTPUT | jq '(.jobs[0].write.bw / 1024) + '"$TOTAL_WRITE_BW")
    done

   # Calculate averages
    AVG_READ_IOPS=$(echo "$TOTAL_READ_IOPS / $NUMFILES" | bc -l)
    AVG_WRITE_IOPS=$(echo "$TOTAL_WRITE_IOPS / $NUMFILES" | bc -l)
    AVG_READ_BW=$(echo "$TOTAL_READ_BW / $NUMFILES" | bc -l)
    AVG_WRITE_BW=$(echo "$TOTAL_WRITE_BW / $NUMFILES" | bc -l)

    # Format and print averages, omitting 0 results
    [ "$(echo "$AVG_READ_IOPS > 0" | bc)" -eq 1 ] && printf "Average Read IOPS: %'.2f\n" $AVG_READ_IOPS
    [ "$(echo "$AVG_WRITE_IOPS > 0" | bc)" -eq 1 ] && printf "Average Write IOPS: %'.2f\n" $AVG_WRITE_IOPS
    [ "$(echo "$AVG_READ_BW > 0" | bc)" -eq 1 ] && printf "Average Read Bandwidth (MB/s): %'.2f\n" $AVG_READ_BW
    [ "$(echo "$AVG_WRITE_BW > 0" | bc)" -eq 1 ] && printf "Average Write Bandwidth (MB/s): %'.2f\n" $AVG_WRITE_BW

}

# Run tests
perform_test randwrite
perform_test randread
perform_test write
perform_test read
perform_test readwrite

# Clean up
for ((i=1; i<=NUMFILES; i++)); do
    rm "$TEST_DIR/fio_test_file_$i"
done
