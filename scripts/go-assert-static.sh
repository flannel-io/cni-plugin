#!/bin/sh
if [ -z "$*" ]; then
    echo "usage: $0 file1 [file2 ... fileN]"
fi
for exe in "${@}"; do
    if [ ! -x "${exe}" ]; then
        echo "$exe: file not found" >&2
        exit 1
    fi

    case $GOOS in
        linux)
            if  ! file "${exe}" | grep -E '.*ELF.*executable, .*, statically linked,.*'; then
                file "${exe}" >&2
                echo "${exe}: not a statically linked executable" >&2
                exit 1
            fi
        ;;
        windows)
            if ! ldd "${exe}"  2>&1 | grep -qE '.*not a dynamic executable' && ! objdump -T "${exe}" 2>&1 | tr -d '\n' | grep -E '.*pei-x86-64.*not a dynamic object.*no symbols'; then
                file "${exe}" >&2
                echo "${exe}: not a statically linked Windows executable" >&2
                exit 1
            fi 
        ;;
        *)
        echo "GOOS:${GOOS} is not yet supported"
        exit 1
        ;;
    esac
done
