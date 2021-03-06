#!/bin/sh

# This script is inspired from ./openocd.sh, and from both flash_dfu.sh and
# fwversion.sh, included in arduino101-factory_recovery-flashpack.tar.bz2,
# which is available from https://downloadcenter.intel.com/download/25470

DFUUTIL_EXE=${DFUUTIL:-dfu-util}
DFUUTIL_CMD="$DFUUTIL_EXE -d,$DFUUTIL_PID"

test_exe() {
    if ! which $DFUUTIL_EXE >/dev/null 2>&1; then
        echo "Error: Unable to locate dfu-util executable: $DFUUTIL_EXE"
        exit 1
    fi
}

test_img() {
    if [ ! -f "$DFUUTIL_IMG" ]; then
        echo "Error: Unable to locate binary image: $DFUUTIL_IMG"
        exit 1
    fi
}

find_dfu() {
    $DFUUTIL_CMD -l |grep "$DFUUTIL_ALT" >/dev/null 2>&1
}

do_flash() {
    test_exe
    test_img

    # Wait until DFU device is ready
    reset_dfu=0
    if ! find_dfu; then
        reset_dfu=1
        echo "Please reset your board to switch to DFU mode..."
        until find_dfu; do
            sleep 0.1
        done
    fi

    # Allow DfuSe based devices by checking for DFUUTIL_DFUSE_ADDR
    if [ -n "${DFUUTIL_DFUSE_ADDR}" ]; then
        DFUUTIL_CMD="${DFUUTIL_CMD} -s ${DFUUTIL_DFUSE_ADDR}:leave"
    fi

    # Flash DFU device with specified image
    # Do NOT reset with -R, to avoid random 'error resetting after download'
    $DFUUTIL_CMD -a $DFUUTIL_ALT -D $DFUUTIL_IMG
    ok=$?
    if [ $ok -eq 0 -a $reset_dfu -eq 1 ]; then
        echo "Now reset your board again to switch back to runtime mode."
    fi
    return $ok
}

CMD=$1
shift

case "$CMD" in
  flash)
    do_flash "$@"
    ;;
  *)
    echo "Unsupported command '$CMD'"
    exit 1
    ;;
esac

