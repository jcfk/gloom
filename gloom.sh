#!/bin/bash

HELP="USAGE:
  gloom [OPTION...] _file_

Options:
  --detach              Open in background, in new window
  --tabbed _tabbedxid_  Open window under instance of tabbed specified by tabbedxid
  --no-tabbed           Do not create a new instance of tabbed
  --print-opener        Only print name of program used to open file and exit
  --help                Print this message"

err() {
    echo "$1" ; exit 1
}

if_print_and_exit() {
    if [ "$PRINT_OPENER" ] ; then
        echo "$1" ; exit 1
    fi
}

# 1. Handle args

DETACH=""
TABBED_XID=""
NO_TABBED=""
PRINT_OPENER=""
ARGS=()

while [ "$1" ] ; do
    case "$1" in
        "--detach")
            DETACH=1
        ;;
        "--tabbed")
            TABBED_XID="$2"
            shift
        ;;
        "--no-tabbed")
            NO_TABBED=1
        ;;
        "--print-opener")
            PRINT_OPENER=1
        ;;
        "--help")
            echo "$HELP" ; exit 0
        ;;
        *)
            if [ "${1:0:1}" == "-" ] ; then
                err "unknown option \"$1\""
            else
                ARGS+=("$1")
            fi
        ;;
    esac
    shift
done

if [ "${ARGS[0]}" ] ; then
    FILE="${ARGS[0]}"
else
    err "no file provided"
fi

# 2. Open file

EXT="${FILE##*.}"
case "$EXT" in
    epub)
        calibre "$FILE" >/dev/null 2>&1 &
        exit 0
        ;;
    pdf|djvu|PDF|ps)
        if_print_and_exit "zathura"

        if [ "$TABBED_XID" ] ; then
            zathura -e "$TABBED_XID" -c "$SYSTEM/config/zathura" \
                "$FILE" >/dev/null 2>&1 &
        else
            if [ "$NO_TABBED" ] ; then # by default it creates a new instance of tabbed
                zathura -c "$SYSTEM/config/zathura" \
                    "$FILE" >/dev/null 2>&1 &
            else
                tabbed -c -r 2 zathura -e '' -c "$SYSTEM/config/zathura" \
                    "$FILE" >/dev/null 2>&1 &
            fi
        fi
        exit 0
        ;;
    jpeg|JPEG|jpg|JPG|png|PNG|webp|tif|avif|tiff)
        feh --start-at "$FILE" >/dev/null 2>&1 &
        exit 0
        ;;
    gif)
        sxiv -a "$FILE" >/dev/null 2>&1 &
        exit 0
        ;;
    svg)
        feh --conversion-timeout 1 "$FILE" >/dev/null 2>&1 &
        exit 0
        ;;
    mp3|m4a|oga|ogg|wav|aiff|au)
        mpv --no-audio-display "$FILE"
        exit 0
        ;;
    mp4|mkv|mov|webm|ogv|MOV)
        mpv "$FILE" >/dev/null 2>&1 &
        exit 0
        ;;
    *)
        if_print_and_exit "vim"

        if [ "$DETACH" ] ; then
            st -e bash -i -c "vim \"$FILE\"" &
        else
            vim "$FILE"
        fi
        exit 0
        ;;
esac

