@echo off
REM #-----------------------------------------#
REM #-- return the available ShopBot tools ---#
REM #---- connected to the local network -----#
REM #------ using a scan over TCP/IP ---------#
REM #------ Support IPV4 adress only ---------#
REM #------ Support IP type B and C ----------#
REM #----- Does NOT support localhost --------#
REM #-----------------------------------------#

cls
set execPath=%~dp0 
echo %execPath%
pause
@echo on
for /f "delims=" %%i in ('ipconfig | FOR /F "tokens=1" %%a IN (file.txt) DO ECHO %%a | tr -s "\n"') do Set list_itf=%%i

for itf in $list_itf;
do
	
	ip_addr=$(ifconfig $itf | grep "inet adr" | grep -oE 'adr:((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' |  awk -F ":" '{ print $2 }')
	ip_mask=$(ifconfig $itf | grep "inet" | grep -oE '255.((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){2}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])')	
	is_C=$(echo $ip_mask | grep 255.255.255. | wc -l)
	if [ $is_C -eq 1 ] #mask class C
	then
		ip_netw=$(echo $ip_addr | awk -F "." '{ print $1"."$2"."$3}')

		for i in `seq 0 1 254`;
		do
			
			eval 'ping $ip_netw.$i -c 1  -W 1ls 1>/dev/null 2>&1 ; if [ $? -eq 0 ] ;then echo $ip_netw.$i; fi >> "$execPath/ip.dat"' &
		done
	else
		is_B=$(echo $ip_mask | grep 255.255. | wc -l)
		if [ $is_B -eq 1 ]  #mask class B
		then
			ip_netw=$(echo $ip_addr | awk -F "." '{ print $1"."$2}')
			for i in `seq 0 1 254`;
			do
				for j in `seq 0 1 254`;
				do
					eval 'ping $ip_netw.$i.$j -c 1  -W 1 1>/dev/null 2>&1  ; if [ $? -eq 0 ] ;then echo $ip_netw.$i.$j; fi >> "$execPath/ip.dat"' &
				done
			done
		fi

	fi
done

wait # wait for every processus to end


cat "$execPath/ip.dat" | sort | uniq >"$execPath/ip2.dat"; cp "$execPath/ip2.dat" "$execPath/ip.dat"; rm "$execPath/ip2.dat";

for line in $(cat $execPath/ip.dat);
	do eval '"$execPath/are_you_a_sbt" "$line" 2> /dev/null ; if [ $? -eq 0 ]; then echo $line; fi'&
done
wait
rm "$execPath/ip.dat" 2> /dev/null
