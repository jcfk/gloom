#!/bin/bash

HELP="USAGE:
  gloom [OPTION...] _file_

Options:
  --detach              Open in background, in new window
  --no-tabbed           Do not create a new instance of tabbed
  --tabbed _tabbedxid_  Open window under instance of tabbed specified by tabbedxid (0x...)
  --print-opener        Only print name of program used to open file and exit
  --print-tabbed-xid    If opening a new tabbed instance, print its xid to stdout
  --rg-line-num         Plaintext filenames may have a line number appended with colon (ex. 
                        file.txt:53), and will open there
  --help                Print this message"

err() {
    echo "$1" ; exit 1
}

if_print_and_exit() {
    if [[ "$PRINT_OPENER" ]] ; then
        echo "$1" ; exit 0
    fi
}

# 1. Handle args

DETACH=""
TABBED_XID=""
NO_TABBED=""
PRINT_OPENER=""
PRINT_TABBED_XID=""
RG_LINE_NUM=""
ARGS=()

while [[ "$1" ]] ; do
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
        "--print-tabbed-xid")
            PRINT_TABBED_XID=1
        ;;
        "--rg-line-num")
            RG_LINE_NUM=1
        ;;
        "--help")
            echo "$HELP" ; exit 0
        ;;
        *)
            if [[ "${1:0:1}" == "-" ]] ; then
                err "unknown option \"$1\""
            else
                ARGS+=("$1")
            fi
        ;;
    esac
    shift
done

if [[ "${ARGS[0]}" ]] ; then
    FILE="${ARGS[0]}"
    echo "$FILE" >> /home/jacob/main/sync/corpus/system/logs/glooms
else
    err "no file provided"
fi

if [[ "$RG_LINE_NUM" ]] ; then
    FILENAME="${FILE%:*}"
    LINE_NUM="${FILE##*:}"
    FILE="$FILENAME"
fi

# 2. Open file

EXT="${FILE##*.}"
case "$EXT" in
    epub|mobi)
        if_print_and_exit "calibre"

        calibre "$FILE" >/dev/null 2>&1 &
        exit 0
        ;;
    pdf|djvu|PDF|ps)
        if_print_and_exit "zathura"

        if [[ "$NO_TABBED" ]] ; then
            zathura -c "$SYSTEM/config/zathura" "$FILE" >/dev/null 2>&1 &
            exit 0
        fi

        if [[ "$TABBED_XID" ]] ; then
            zathura -e "$TABBED_XID" -c "$SYSTEM/config/zathura" "$FILE" >/dev/null 2>&1 &
            exit 0
        fi

        NEW_XID=$(tabbed -d -b -c -r 2 \
            zathura -e '' -c "$SYSTEM/config/zathura" "$FILE" 2>/dev/null)
        if [[ $PRINT_TABBED_XID ]] ; then
            echo "$NEW_XID"
        fi
        exit 0
        ;;
    dvi)
        if_print_and_exit "evince"

        evince "$FILE" >/dev/null 2>&1 &
        exit 0
        ;;
    jpeg|JPEG|jpg|JPG|png|PNG|webp|tif|avif|tiff|heic)
        if_print_and_exit "feh"

        feh --start-at "$FILE" >/dev/null 2>&1 &
        exit 0
        ;;
    gif)
        if_print_and_exit "sxiv"

        sxiv -a "$FILE" >/dev/null 2>&1 &
        exit 0
        ;;
    svg)
        if_print_and_exit "feh"

        feh --conversion-timeout 1 "$FILE" >/dev/null 2>&1 &
        exit 0
        ;;
    mp3|m4a|oga|ogg|wav|aiff|au|ogx|wma)
        if_print_and_exit "mpv"

        if [[ "$DETACH" ]] ; then
            st -e bash -i -c "mpv --no-audio-display \"$FILE\"" >/dev/null 2>&1 &
        else
            mpv --no-audio-display "$FILE"
        fi
        exit 0
        ;;
    mp4|mkv|mov|webm|ogv|MOV)
        if_print_and_exit "mpv"

        mpv "$FILE" >/dev/null 2>&1 &
        exit 0
        ;;
    *)
        if_print_and_exit "vim"

        if [[ "$DETACH" ]] ; then
            if [[ "$RG_LINE_NUM" ]] ; then
                st -e bash -i -c "vim +$LINE_NUM \"$FILE\"" >/dev/null 2>&1 &
            else
                st -e bash -i -c "vim \"$FILE\"" >/dev/null 2>&1 &
            fi
        else
            if [[ "$RG_LINE_NUM" ]] ; then
                vim +$LINE_NUM "$FILE"
            else
                vim "$FILE"
            fi
        fi
        exit 0
        ;;
esac

