#!/bin/sh
#===========================================================================================================================================
# Name: gpa [Gestion de procesos de aplicaciones]
# Autor: Alberto Fernandez 
# Purpose: Monitorizacion, parada y arranque, loggin  de los procesos de un sistema o aplicacion
# version 9.8.1 Julio 2014
# Copyright AFF - 2014
#==========================================================================================================================================

RUTA_INST=/var/opt/apps/asis/scripts/gpa
cd $RUTA_INST
#set -x
clear
. ./CFG/var.cfg
. ./CFG/os_version.cfg 

#if [ `resize|grep -i "columns="|awk '{ print $2 }' FS="="|sed 's/;//g'` -lt 136 ]
#	then
#		echo "\n   Las dimensiones de la terminal no permiten la ejecucion de gpa.sh"
#		echo "   Agranda la terminal y ejecuta de nuevo el programa \n"
#		exit 100
#fi

header_title ()
	{
	date_titulo=`date '+%H:%M'|sed 's/://g'`
        echo " "
        echo ${AZUL}"\c"
        echo "     ${BG_WHITE}=================================================================================================================================${BG_OFF}"
        echo "     ${DOBLEDOWN}GPA $titOFF --- Gestion de Procesos de Aplicaciones - $date_titulo ---$titOFF ${DOBLEOFF}"
        echo ${AZUL}"\c"
        echo "     ${BG_WHITE}=================================================================================================================================${BG_OFF}"
        echo ${OFF}"\c"
	}
header_title
if [ "${1}" = "-ver" ] || [ "${1}" = "-version" ]
        then
                echo " "
                echo "     ${tit}Name: ${titOFF}Gestion de Procesos de Aplicaciones "
                echo "     ${tit}Autor: ${titOFF} Alberto Fernandez Copyright 2014"
                echo "     ${tit}Version: ${titOFF} v9.8.1 Julio 2014"
                echo " "
fi
if [ "${1}" = "-h" ] || [ "${1}" = "-help" ]
        then
                echo " "
                echo "     ${tit}Monitorizacion: ${titOFF} $0"
                echo "     ${tit}Monitori. extendida: ${titOFF} $0 -ext"
		echo "     ${tit}Guarda Logs: ${titOFF} $0 -log"
                echo "     ${tit}Ayuda: ${titOFF} $0 -h / $0 -help"
		echo "     ${tit}Parar Procesos: ${titOFF} $0 -parar <nom_proceso1> <nom_proceso2> <nom_proceso3> ..."
		echo "     ${tit}Arrancar Procesos: ${titOFF} $0 -arrancar <nom_proceso1> <nom_proceso2> <nom_proceso3> ..."
		echo "     ${tit}Muestra la version : ${titOFF} $0 -ver o -version"
		echo "     ================================================================================================================================="
                echo "     ${tit}ESTRUCTURA ./CFG/procesos.lst $titOFF"
                echo "     Orden_Ejecucion; Usuario; Activo/No Activo; Nombre_del_proceso; Cadena_a_monitorizar; LOGS; Script_de_parada; Script_de_arranque "
		echo " "
fi

gpa_pinta ()
{
echo "     .-------------------------------------------------------------------------------------------------------------------------------."
printf "%-50s %-10s %-10s %-15s %-10s %-12s %-5s %-5s %-5s \n" "     |   Nombre" "Estado" "Usuario" "Uptime" "PID" "Fecha" "%CPU" "%Mem" "RSS     |";
echo "     .-------------------------------------------- ---------- ---------- --------------- ---------- ------------ ----- ----  --------."
cont=1
contFIN=`cat ./CFG/procesos.lst|wc -l`
contFIN=`expr $contFIN + 1`
while [ $cont -lt $contFIN ]
        do
        i=`cat ./CFG/procesos.lst|sed -n ${cont}p|awk '{print $5}' FS=";"`
                        if [ "${i}" = "" ]
                                then
                                echo "    No hay cadena a monitorizar, revise el archivo de configuracion procesos.lst"
				exit 101
                                else
                                        if [ `${OS_PS_EXT} | grep -i "${i}" |grep -v grep |wc -l 2> /dev/null`  -gt 0 ]
                                                then
							pidproceso=`${OS_PS_EXT} | grep -i "${i}" |grep -v grep |cut -c1-1000|awk '{print $2}'|sed -n 1p 2> /dev/null`
							tiempoproceso=`ps -o etime -p $pidproceso | grep [0-9]|awk '{print $1}'`
							porce_cpu=`ps -o pcpu -p ${pidproceso} 2>/dev/null |grep -v 'CPU'`
							porce_mem=`ps -o pmem -p ${pidproceso} 2>/dev/null |grep -v 'MEM'`
							RSSproceso=`ps -o rss -p ${pidproceso} 2>/dev/null|grep -v 'RSS'`
							fechaproceso=`${OS_PS} | grep -wi "${pidproceso}" |grep -v grep|grep -v sleep | awk '{print $5,$6}'|sed -n 1p`
                                                        apodo_proceso=`grep "${i}" ./CFG/procesos.lst |awk '{print $4}' FS=";"|sed -n 1p 2>/dev/null`
                                                        usu_proceso=`${OS_PS_EXT} | grep -i "${i}" |grep -v grep |cut -c1-1000|awk '{print $1}'|sed -n 1p 2> /dev/null`
							usu_proceso_indicado=`cat ./CFG/procesos.lst|sed -n ${cont}p|awk '{print $2}' FS=";"`
							if [ "$usu_proceso" = "$usu_proceso_indicado" ]
								then
									printf "%-51s %-20s %-10s %-15s %-10s %-12s %-5s %-5s %-10s  \n" "         $apodo_proceso" "$OK" "$usu_proceso" "$tiempoproceso" "$pidproceso" "$fechaproceso" "$porce_cpu" "$porce_mem" "$RSSproceso"
								else
									printf "%-51s %-20s %-21s %-15s %-10s %-12s %-5s %-5s %-10s  \n" "         $apodo_proceso" "$OK" "${RED}$usu_proceso${REDOF}" "$tiempoproceso" "$pidproceso" "$fechaproceso" "$porce_cpu" "$porce_mem" "$RSSproceso"
							fi
							if [ `echo $TODOS_PARAMETROS|grep "log" |wc -l` -eq 1 ]
								then
									echo "$DATE_FOR_LOG | OK | $apodo_proceso con PID=$pidproceso corriendo como $usu_proceso desde $tiempoproceso" >> $LOG_GPA_GLOBAL
								else
									echo "" >> /dev/null
							fi
							if [ `echo $TODOS_PARAMETROS|grep "ext" |wc -l` -eq 1 ]
                                                                then
                                                                        printf "%1s \n" "           ${tit}${i}${titOFF}"
                                                                        a=`cat ./CFG/procesos.lst|sed -n ${cont}p|awk '{print $6}' FS=";"`
                                                                        for g in $a
                                                                                do
                                                                                        printf "%-1s \n" "            LOGS: ${tit2}${g}${titOFF}"
                                                                                done
#                                                                       printf "%1s \n" "            LOGS: ${tit2}${a}${titOFF}"
                                                                        echo "     .--------------------------------------------------------------------------------------------------------------------------------."
                                                        fi
                                                else
                                                        apodo_proceso=`grep "${i}" ./CFG/procesos.lst |awk '{print $4}' FS=";"|sed -n 1p 2>/dev/null`
                                                        if [ `grep -iw "${apodo_proceso}" ./CFG/procesos.lst |awk '{ print $3 }' FS=";"` -eq 0 ]
                                                                then
                                                                        printf "%-49s %-20s %-10s %-15s %-13s \n" "         $apodo_proceso" "$noActivo"
									if [ `echo $TODOS_PARAMETROS|grep "log" |wc -l` -eq 1 ]
										then
											echo "$DATE_FOR_LOG | No Activo | $apodo_proceso" >> $LOG_GPA_GLOBAL
										else
											echo "" > /dev/null
									fi
                                                                else
                                                                        printf "%-51s %-20s %-10s %-15s %-13s \n" "         $apodo_proceso" "$noOK"
									if [ `echo $TODOS_PARAMETROS|grep "log" |wc -l` -eq 1 ]
                                                                                then
                                                                                        echo "$DATE_FOR_LOG | No OK | $apodo_proceso" >> $LOG_GPA_GLOBAL
                                                                                else
                                                                                        echo "" > /dev/null
                                                                        fi

                                                        fi
							if [ `echo $TODOS_PARAMETROS|grep "ext" |wc -l` -eq 1 ]
                                                                then
                                                                        printf "%-1s \n" "           ${tit}${i}${titOFF}"
                                                                        a=`cat ./CFG/procesos.lst|sed -n ${cont}p|awk '{print $6}' FS=";"`
                                                                        for g in $a
                                                                                do
                                                                                        printf "%-1s \n" "            LOGS: ${tit2}${g}${titOFF}"
                                                                                done
                                                              #         printf "%-1s \n" "            LOGS: ${tit2}${a}${titOFF}"
                                                                        echo "     .--------------------------------------------------------------------------------------------------------------------------------."
                                                        fi
                                        fi
                        fi
                cont=`expr $cont + 1`
        done
date_muestro_footer=`date +'%d-%m-%y'`
echo ${AZUL}"\n\c"
echo "     ${BG_WHITE}=================================================================================================================================${BG_OFF}"
echo "     ${tit}Host: ${titOFF}`uname -s` `uname -a |awk '{print $2}'` $USER $date_muestro_footer"
echo "     ${tit}Info: ${titOFF}${SHELL}`uptime`"
echo ${AZUL}"\c"
echo "     ${BG_WHITE}=================================================================================================================================${BG_OFF}${titOFF}\n"
}
comprueba_sigue_arranca ()
        {
                until [ `${OS_PS_EXT} | grep -i "${1}" |grep -v grep |wc -l 2> /dev/null` -gt 0 ]
                        do
                                echo "Revisa script de Arranque" 
                        done
        }
comprueba_sigue_para ()
        {
                until [ `${OS_PS_EXT} | grep -i "${1}" |grep -v grep |wc -l 2> /dev/null` -lt 1 ]
                        do
                                echo "Revisa Script de parada"
                        done
        }
if [ "$1" = "-arrancar" ]
	then
		LISTA_PROCESOS_ARRANCAR=`echo "$@" |sed 's/\-arrancar//g'`
		if [ "$LISTA_PROCESOS_ARRANCAR" = "" ]
			then
				echo "\n     No hay ningun proceso en la lista de arrancar, exit \n"
				exit 102
		fi
		for z in $LISTA_PROCESOS_ARRANCAR
			do
				if [ `cat ./CFG/procesos.lst|awk '{ print $4 }' FS=";"|grep -wi $z |grep -v grep|wc -l` -eq 1 ]
					then
						echo "\n     El proceso $z esta en la lista de procesos... continue"
					else
						echo "\n     El proceso $z no esta en la lista de procesos... exit\n"
						exit 103
				fi
			done
		echo "\n     Estoy arrancando ... "
		for x in $LISTA_PROCESOS_ARRANCAR
			do
				residuo1=`grep $x ./CFG/procesos.lst |awk '{ print $1, $5 }' FS=";"`
				echo $residuo1 >> ./TMP/residuo_$$.tmp
				LISTA_PROCESOS_ARRANCAR_ORDE=`echo "${LISTA_PROCESOS_ARRANCAR_ORDE} ${residuo1}"`
			done
		cat ././TMP/residuo_$$.tmp |sort -k1n|awk '{ print $2 }' > ./TMP/residuo2_$$.tmp
		for w in `cat ././TMP/residuo2_$$.tmp` 
			do
			if [ `${OS_PS_EXT} | grep -i "${w}" |grep -v grep |wc -l 2> /dev/null`  -gt 0 ]
			then
				echo " "
				echo "     Actuando sobre ...  $w "
				echo "     ERROR!! Operacion NO REALIZADA"
				echo "     El proceso $w ya esta corriendo, por lo que no arrancara de nuevo"
				echo " "
				echo "     ----------------------------------------------------------------------------------------------------------------------------------"
			else
				#echo $w
				if [ `grep -iw $w ./CFG/procesos.lst |wc -l` -eq 1 ]
                                        then
                                                ejecuta_cmd=`grep -iw $w ./CFG/procesos.lst |awk '{ print $8 }' FS=";"`
						usuario_actual=`id |awk '{ print $1 }'|awk '{ print $2 }' FS="(" |sed 's/)//g' |sed -n 1p`
						usuario_proceso=`grep -iw $w ./CFG/procesos.lst| awk '{ print $2 }' FS=";"`
						if [ "${usuario_actual}" = "${usuario_proceso}" ]
							then
								if [ `grep -i $w ./CFG/procesos.lst | awk '{ print $3 }' FS=";"` -eq 1 ]
								then
										echo " "
										echo "     Lanzamos el proceso $ejecuta_cmd "
										echo " "
										$ejecuta_cmd 2>&1 1> ./TRZ/traza_$$.trz
										comprueba_sigue_arranca $w
										echo "     Arrancado el proceso $ejecuta_cmd "
										echo " "
										echo "     ----------------------------------------------------------------------------------------------------------------------------------"
									else
										echo " "
										echo "     Actuando sobre ... $w"
										echo "     ATENCION!! "
										echo "     Has marcado este proceso como NO ACTIVO"
										echo "     Aun asi, Quieres arrancarlo? S/N : \c\c"
										read respuesta_arranque
										echo " "
										if [ "${respuesta_arranque}" = "S" ] || [ "${respuesta_arranque}" = "s" ]
											then
												echo "          Lanzamos el arranque del proceso $ejecuta_cmd "
												echo " "
												$ejecuta_cmd 2>&1 1> ./TRZ/traza_$$.trz
												comprueba_sigue_arranca $w
												echo "          Arrancado el proceso $ejecuta_cmd "
												echo " "
												echo "     ----------------------------------------------------------------------------------------------------------------------------------"
											else
												echo "          ERROR!! Operacion NO REALIZADA"
												echo "          El proceso $w no se arranca"
												echo " "
												echo "     ----------------------------------------------------------------------------------------------------------------------------------"
										fi
								fi
							else
								echo " "
								echo "     Actuando sobre ... $w"
								echo "     ERROR!! Operacion NO REALIZADA"
								echo "     Estas con el usuario $usuario_actual y necesitas ser $usuario_proceso"
								echo "     Logueate con el usuario correcto !!"
								echo " "
								echo "     ----------------------------------------------------------------------------------------------------------------------------------"

						fi
					else
						echo "hola" > /dev/null
                                fi
			fi
			done
		LISTA_PROCESOS_ARRANCAR_ORDE=`echo $LISTA_PROCESOS_ARRANCAR_ORDE |tr -cs '[a-zA-Z0-9]' '[\n*]' |sort -n`
                #echo $LISTA_PROCESOS_ARRANCAR_ORDE
rm ./TMP/residuo_$$.tmp ./TMP/residuo2_$$.tmp
fi

if [ "$1" = "-parar" ]
	then
		LISTA_PROCESOS_PARAR=`echo "$@" |sed 's/\-parar//g'`
                if [ "$LISTA_PROCESOS_PARAR" = "" ]
                        then
                                echo "\n     No hay ningun proceso en la lista de parar, exit \n"
                                exit 104
                fi		
                for z in $LISTA_PROCESOS_PARAR
                        do
                                if [ `cat ./CFG/procesos.lst|awk '{ print $4 }' FS=";"|grep -wi $z |grep -v grep|wc -l` -eq 1 ]
                                        then
                                                echo "\n     El proceso $z esta en la lista de procesos... continue"
                                        else
                                                echo "\n     El proceso $z no esta en la lista de procesos... exit\n"
                                                exit 105
                                fi
                        done
		for x in $LISTA_PROCESOS_PARAR
			do
				residuo1=`grep $x ./CFG/procesos.lst |awk '{ print $1, $5 }' FS=";"`
                                echo $residuo1 >> ./TMP/residuo_$$.tmp
				LISTA_PROCESOS_PARAR_ORDE=`echo "${LISTA_PROCESOS_PARAR_ORDE} ${residuo1}"`
			done
		echo " "
		echo "     Estoy parando ..."
		cat ./TMP/residuo_$$.tmp |sort -k1n -r |awk '{ print $2 }' > ./TMP/residuo2_$$.tmp
		for w in `cat ./TMP/residuo2_$$.tmp`
                        do
			if [ `${OS_PS_EXT} | grep -iw "${w}" |grep -v grep |wc -l 2> /dev/null` -gt 0 ]
                        	then
                                	#echo $w
                                		if [ `grep -iw $w ./CFG/procesos.lst |wc -l` -eq 1 ]
                                        		then
                                                		ejecuta_cmd=`grep -iw $w ./CFG/procesos.lst |awk '{ print $7 }' FS=";"`
                                       				usuario_actual=`id |awk '{ print $1 }'|awk '{ print $2 }' FS="(" |sed 's/)//g' |sed -n 1p`
                                                		usuario_proceso=`grep -iw $w ./CFG/procesos.lst| awk '{ print $2 }' FS=";"`
                                                		if [ "${usuario_actual}" = "${usuario_proceso}" ]
                                                        		then
																	echo " "
																	echo "     Lanzamos la parada del proceso $ejecuta_cmd"
																	echo " "
																	$ejecuta_cmd 2>&1 1> ./TRZ/traza_$$.trz
                                                                	comprueba_sigue_para $w
																	echo "     Proceso $w parado "
																	echo " "
																	echo "     ----------------------------------------------------------------------------------------------------------------------------------"
                                                        		else
                                                                		echo " "
                                                                		echo "     Estas con el usuario $usuario_actual y necesitas ser $usuario_proceso"
                                                                		echo "     Logueate con el usuario correcto !!"
                                                                		echo " "
																		echo "     ----------------------------------------------------------------------------------------------------------------------------------"
                                                		fi
												else
													echo "hola" > /dev/null
										fi
							else
								echo " "
								echo "     ERROR!! Operacion NO REALIZADA"
								echo "     No se puede parar el proceso $w porque no esta arrancado"
								echo " "
								echo "     ----------------------------------------------------------------------------------------------------------------------------------"
			fi
        done
                LISTA_PROCESOS_PARAR_ORDE=`echo $LISTA_PROCESOS_PARAR_ORDE |tr -cs '[a-zA-Z0-9]' '[\n*]' |sort -n`
rm ./TMP/residuo_$$.tmp ./TMP/residuo2_$$.tmp
	else
			echo " " > /dev/null
fi


#Fin y llamada al gpa_pinta
gpa_pinta
rm -rf ./TMP/* 2>/dev/null
