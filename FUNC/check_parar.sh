                until [ `${OS_PS_EXT} | grep -i "${1}" |grep -v grep |wc -l 2> /dev/null` -lt 1 ]
                        do
                                echo "Revisa Script de parada"
                        done

