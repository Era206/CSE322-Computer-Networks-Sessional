#Create a simulator object
set ns [new Simulator]

#Define different colors for data flows (for NAM)
$ns color 1 Blue
$ns color 2 Red

#Open the NAM file and trace file
set nam_file [open animation.nam w]
set trace_file [open trace.tr w]
$ns namtrace-all $nam_file
$ns trace-all $trace_file


#Define a 'finish' procedure
proc finish {} {
    global ns nam_file trace_file
    $ns flush-trace 
    #Close the NAM trace file
    close $nam_file
    close $trace_file
    #Execute NAM on the trace file
    # exec nam out.nam &
    exit 0
}

#Create four nodes
# set n0 [$ns node]
# set n1 [$ns node]
# set n2 [$ns node]
# set n3 [$ns node]

set nodeCount  [lindex $argv 0] 

for {set i 0} {$i < $nodeCount} {incr i} {
    set n($i) [$ns node]
}


#Create links between the nodes
# ns <link-type> <node1> <node2> <bandwidht> <delay> <queue-type-of-node2>
# $ns duplex-link $n0 $n2 2Mb 10ms DropTail
# $ns duplex-link $n1 $n2 2Mb 10ms DropTail
# $ns duplex-link $n2 $n3 1.7Mb 20ms DropTail


set left [expr ( $nodeCount / 2) - 1 ]

for {set i 0} {$i < $left} {incr i} {
    $ns duplex-link $n($i) $n($left) 2Mb 10ms DropTail
}

set right [expr ( $nodeCount / 2) ]
$ns duplex-link $n($left) $n($right) 2Mb 10ms DropTail
set end [expr $right + 1 ]

for {set i $end} {$i < $nodeCount} {incr i} {
    $ns duplex-link $n($right) $n($i) 2Mb 10ms DropTail
}



#Set Queue Size of link (n2-n3) to 10
# $ns queue-limit $n2 $n3 20
# $ns duplex-link-op $n2 $n3 queuePos 0.5

#Give node position (for NAM)
#$ns duplex-link-op $n0 $n2 orient right-down
#$ns duplex-link-op $n1 $n2 orient right-up
#$ns duplex-link-op $n2 $n3 orient right

#Monitor the queue for link (n2-n3). (for NAM)
# $ns duplex-link-op $n2 $n3 queuePos 0.5


#Setup a TCP connection
#Setup a flow
# set tcp [new Agent/TCP]
# $ns attach-agent $n0 $tcp
# set sink [new Agent/TCPSink]
# $ns attach-agent $n3 $sink
# $ns connect $tcp $sink
# $tcp set fid_ 1

expr { srand(1) }
proc rand { excl_limit } {
    expr { int(rand() * $excl_limit) }
}

set flow [lindex $argv 1]
set maxSent [lindex $argv 2]

for {set k 0} {$k < $flow
} {incr k} {

    set i [rand $left]
    set j [expr $i + $right]

    # set tcp1 [new Agent/TCP]
    set tcp1 [new Agent/TCP/Vegas]
   


    # $tcp1 tracevar nodes
    $ns attach-agent $n($i) $tcp1
    set sink1 [new Agent/TCPSink]
    $ns attach-agent $n($j) $sink1
    $ns connect $tcp1 $sink1
    $tcp1 set fid_ $k
    $tcp1 set maxseq_ $maxSent

    set ftp1 [new Application/FTP]
    $ftp1 attach-agent $tcp1
    $ftp1 set type_ FTP
    $ns at 1.0 "$ftp1 start"
    $ns at 50.0 "$ftp1 stop"
}

#Detach tcp and sink agents (not really necessary)
# $ns at 4.5 "$ns detach-agent $n0 $tcp ; $ns detach-agent $n3 $sink"

#Call the finish procedure after 5 seconds of simulation time
$ns at 5.0 "finish"


#Run the simulation
$ns run
