BEGIN {
	max_node = 2000;
	nSentPackets = 0.0 ;		
	nReceivedPackets = 0.0 ;
	rTotalDelay = 0.0 ;
	max_pckt = 10000;
	
	idHighestPacket = 0;
	idLowestPacket = 100000;
	rStartTime = 10000.0;
	rEndTime = 0.0;
	nReceivedBytes = 0;

	nDropPackets = 0.0;

	total_energy_consumption = 0;

	temp = 0;
	
	for (i=0; i<max_node; i++) {
		energy_consumption[i] = 0;		
	}

	total_retransmit = 0;
	for (i=0; i<max_pckt; i++) {
		retransmit[i] = 0;		
	}
	#printf("Inside awk file ... file_throughput = %s, file_delay = %s, file_deliveryRatio = %s \
	#file_dropRatio = %s, file_energyConsumption = %s\n", #file_throughput,file_delay,file_deliveryRatio,file_dropRatio, file_energyConsumption) >> "Check.txt";;
	#printf("Changed variable = %d\n", valueChanged) >> "Check.txt";
	#printf("\n\n") >> "Check.txt";
}

{
#	event = $1;    time = $2;    node = $3;    type = $4;    reason = $5;    node2 = $5;    
#	packetid = $6;    mac_sub_type=$7;    size=$8;    source = $11;    dest = $10;    energy=$14;

	strEvent = $1 ;			rTime = $2 ;
	node = $3 ;
	strAgt = $4 ;			idPacket = $6 ;
	strType = $7 ;			nBytes = $8;

	energy = $13;			total_energy = $14;
	idle_energy_consumption = $16;	sleep_energy_consumption = $18; 
	transmit_energy_consumption = $20;	receive_energy_consumption = $22; 
	num_retransmit = $30;
	
	sub(/^_*/, "", node);
	sub(/_*$/, "", node);

	if (energy == "[energy") {
		energy_consumption[node] = (idle_energy_consumption + sleep_energy_consumption + transmit_energy_consumption + receive_energy_consumption);
#		printf("%d %15.5f\n", node, energy_consumption[node]);
	}

	if( 0 && temp <=25 && energy == "[energy" && strEvent == "D") {
		#printf("%s %15.5f %d %s %15.5f %15.5f %15.5f %15.5f %15.5f \n", strEvent, rTime, idPacket, energy, total_energy, idle_energy_consumption, sleep_energy_consumption, transmit_energy_consumption, receive_energy_consumption);
		temp+=1;
	}

	if ( strAgt == "AGT"   &&   strType == "tcp" ) {
		if (idPacket > idHighestPacket) idHighestPacket = idPacket;
		if (idPacket < idLowestPacket) idLowestPacket = idPacket;

		if(rTime>rEndTime) rEndTime=rTime;
		if(rTime<rStartTime) rStartTime=rTime;

		if ( strEvent == "s" ) {
			nSentPackets += 1 ;	rSentTime[ idPacket ] = rTime ;
#			printf("%15.5f\n", nSentPackets);
		}
#		if ( strEvent == "r" ) {
		if ( strEvent == "r" && idPacket >= idLowestPacket) {
			nReceivedPackets += 1 ;		nReceivedBytes += nBytes;
#			printf("%15.0f\n", nBytes);
			rReceivedTime[ idPacket ] = rTime ;
			rDelay[idPacket] = rReceivedTime[ idPacket] - rSentTime[ idPacket ];
#			rTotalDelay += rReceivedTime[ idPacket] - rSentTime[ idPacket ];
			rTotalDelay += rDelay[idPacket]; 

#			printf("%15.5f   %15.5f\n", rDelay[idPacket], rReceivedTime[ idPacket] - rSentTime[ idPacket ]);
		}
	}

	if( strEvent == "D"   &&   strType == "tcp" )
	{
		if(rTime>rEndTime) rEndTime=rTime;
		if(rTime<rStartTime) rStartTime=rTime;
		nDropPackets += 1;
	}

	if( strType == "tcp" )
	{
#		printf("%d \n", idPacket);
#		printf("%d %15d\n", idPacket, num_retransmit);
		retransmit[idPacket] = num_retransmit;		
	}
}

END {
	rTime = rEndTime - rStartTime ;
	rThroughput = nReceivedBytes*8 / rTime;
	rPacketDeliveryRatio = nReceivedPackets / nSentPackets * 100 ;
	rPacketDropRatio = nDropPackets / nSentPackets * 100;

	for(i=0; i<max_node;i++) {
#		printf("%d %15.5f\n", i, energy_consumption[i]);
		total_energy_consumption += energy_consumption[i];
	}
	if ( nReceivedPackets != 0 ) {
		rAverageDelay = rTotalDelay / nReceivedPackets ;
		avg_energy_per_packet = total_energy_consumption / nReceivedPackets ;
	}

	if ( nReceivedBytes != 0 ) {
		avg_energy_per_byte = total_energy_consumption / nReceivedBytes ;
		avg_energy_per_bit = avg_energy_per_byte / 8;
	}

	for (i=0; i<max_pckt; i++) {
		total_retransmit += retransmit[i] ;		
#		printf("%d %15.5f\n", i, retransmit[i]);
	}


printf( "Throughput: %15.2f \nAverageDelay: %15.5f \nSent Packets: %15.2f \nReceived Packets: %15.2f\
	\nDropped Packets: %15.2f \nPacketDeliveryRatio: %10.2f \nPacketDropRatio: %10.2f\
	\nTotal time: %10.5f\n", rThroughput, rAverageDelay, nSentPackets, nReceivedPackets, nDropPackets, rPacketDeliveryRatio, rPacketDropRatio,rTime) ;

	printf("Total_energy: %15.5f \nAvg_enr_per_bit: %15.5f \nAvg_enr_per_byte: %15.5f\
	\nAvg_enr_per_pckt: %15.5f \nTotal_retransmit: %15.0f\n", total_energy_consumption, avg_energy_per_bit, avg_energy_per_byte, avg_energy_per_packet, total_retransmit);

printf( "Throughput: %15.2f \nAverageDelay: %15.5f \nSent Packets: %15.2f \nReceived Packets: %15.2f\
	\nDropped Packets: %15.2f \nPacketDeliveryRatio: %10.2f \nPacketDropRatio: %10.2f\
	\nTotal time: %10.5f\n", rThroughput, rAverageDelay, nSentPackets, nReceivedPackets, nDropPackets, rPacketDeliveryRatio, rPacketDropRatio,rTime)>> "Check.txt";

	printf("Total_energy: %15.5f \nAvg_enr_per_bit: %15.5f \nAvg_enr_per_byte: %15.5f\
	\nAvg_enr_per_pckt: %15.5f \nTotal_retransmit: %15.0f\n", total_energy_consumption, avg_energy_per_bit, avg_energy_per_byte, avg_energy_per_packet, total_retransmit)>> "Check.txt";
	printf("\n\n") >> "Check.txt";

#This is text format for gnu plot
	# printf("%d %f\n", valueChanged, rThroughput) >> "file_throughput";
	# printf("%d %f\n", valueChanged, rAverageDelay) >> "file_delay";
	# printf("%d %f\n", valueChanged, rPacketDeliveryRatio) >> "file_deliveryRatio";
	# printf("%d %f\n", valueChanged, rPacketDropRatio) >> "file_dropRatio";
	# printf("%d %f\n", valueChanged, total_energy_consumption) >> "file_energyConsumption";	
    printf("%f, %f, %f, %f, %f\n", rThroughput, rAverageDelay, rPacketDeliveryRatio, rPacketDropRatio, total_energy_consumption) ;	


}