#!/bin/sh
if [ -z "$*" ]; then
    echo "usage: $0 file1 [file2 ... fileN]"
fi
for exe in "${@}"; do
    if [ ! -x "${exe}" ]; then
        echo "$exe: file not found" >&2
        exit 1
    fi

    case ${GOOS} in 
        linux)
            echo "verifying that the linux flannel-cni binary is fully statically linked"
            if  ! file "${exe}" | grep -E '.*ELF.*executable, .*, statically linked,.*'; then
                file "${exe}" >&2
                echo "${exe}: not a statically linked executable" >&2
                exit 1
            fi
        ;;
        windows)
            echo "verifying that the windows flannel-cni binary is fully statically linked"
            if (! ldd "${exe}" | grep -E 'not a dynamic executable') && (! objdump -T "${exe}" | grep -E '^.*pei-x86-64$[\s\S]*not\sa\sdynamic\sobject[\s\S]*no\ssymbols'); then
                file "${exe}" >&2
                echo "${exe}: not a statically linked Windows executable" >&2
                exit 1
            fi 
        ;;
        *)
        echo -n "GOOS:${GOOS} is not yet supported"
        exit 1
        ;;
    esac
done

