# simulator
set ns [new Simulator]
#random fix
expr { srand(1) }

# ======================================================================
# Define options

set val(chan)         Channel/WirelessChannel  ;# channel type
set val(prop)         Propagation/TwoRayGround ;# radio-propagation model
set val(ant)          Antenna/OmniAntenna      ;# Antenna type
set val(ll)           LL                       ;# Link layer type
set val(ifq)          Queue/DropTail/PriQueue  ;# Interface queue type
set val(ifqlen)       50                       ;# max packet in ifq
set val(netif)        Phy/WirelessPhy          ;# network interface type
set val(mac)          Mac/802_11               ;# MAC type
# set val(netif)        Phy/WirelessPhy/802_15_4         ;# network interface type
# set val(mac)          Mac/802_15_4              ;# MAC type
set val(rp)           DSDV                     ;# ad-hoc routing protocol 
set val(nn)           [lindex $argv 0]                       ;# number of mobilenodes

#extra part
set val(energymodel_11)    			EnergyModel     ;
set val(initialenergy_11)  			1000            ;# Initial energy in Joules
set val(idlepower_11) 				900e-3			;#Stargate (802.11b) 
set val(rxpower_11) 				925e-3			;#Stargate (802.11b)
set val(txpower_11) 				1425e-3			;#Stargate (802.11b)
set val(sleeppower_11) 				300e-3			;#Stargate (802.11b)
set val(transitionpower_11) 		200e-3			;#Stargate (802.11b)	?
set val(transitiontime_11) 			3				;#Stargate (802.11b)

# =======================================================================
# trace file
set trace_file [open trace.tr w]
$ns trace-all $trace_file

# nam file
set nam_file [open animation.nam w]
$ns namtrace-all-wireless $nam_file 500 500

# topology: to keep track of node movements
set size [lindex $argv 2] 
set topo [new Topography]
$topo load_flatgrid $size $size ;# 500m x 500m area


# general operation director for mobilenodes
create-god $val(nn)


# node configs
# ======================================================================

# $ns node-config -addressingType flat or hierarchical or expanded
#                  -adhocRouting   DSDV or DSR or TORA
#                  -llType	   LL
#                  -macType	   Mac/802_11
#                  -propType	   "Propagation/TwoRayGround"
#                  -ifqType	   "Queue/DropTail/PriQueue"
#                  -ifqLen	   50
#                  -phyType	   "Phy/WirelessPhy"
#                  -antType	   "Antenna/OmniAntenna"
#                  -channelType    "Channel/WirelessChannel"
#                  -topoInstance   $topo
#                  -energyModel    "EnergyModel"
#                  -initialEnergy  (in Joules)
#                  -rxPower        (in W)
#                  -txPower        (in W)
#                  -agentTrace     ON or OFF
#                  -routerTrace    ON or OFF
#                  -macTrace       ON or OFF
#                  -movementTrace  ON or OFF

# ======================================================================

$ns node-config -adhocRouting $val(rp) \
                -llType $val(ll) \
                -macType $val(mac) \
                -ifqType $val(ifq) \
                -ifqLen $val(ifqlen) \
                -antType $val(ant) \
                -propType $val(prop) \
                -phyType $val(netif) \
                -topoInstance $topo \
                -channelType $val(chan) \
                -agentTrace ON \
                -routerTrace ON \
                -macTrace OFF \
                -movementTrace OFF \
                -energyModel $val(energymodel_11) \
                -idlePower $val(idlepower_11) \
                -rxPower $val(rxpower_11) \
                -txPower $val(txpower_11) \
                -sleepPower $val(sleeppower_11) \
                -transitionPower $val(transitionpower_11) \
                -transitionTime $val(transitiontime_11) \
                -initialEnergy $val(initialenergy_11) 

#integer random number generation
proc my_random { range } {
    expr { int(rand() * $range) }
}

#double random number generation
proc my_random_double { range } {
    expr { (rand() * $range ) }
}

# create nodes
set row [lindex $argv 3] 
set col [expr ($val(nn) / $row)]
set node_speed [lindex $argv 4]


for {set i 0} {$i < $row } {incr i} {
    for {set j 0} {$j < $col } {incr j} {
        set x [my_random $size]
        set y [my_random $size]
        #set speed [expr [my_random_double 4] + 1]
        #set speed $node_speed
        # puts $speed
    
        set temp [expr (($i * $col) + $j)]
        set node($temp) [$ns node]
        $node($temp) random-motion 0       ;# disable random motion

        $node($temp) set Y_ [expr ($size * $i) / $row]
        $node($temp) set X_ [expr ($size * $j) / $col]
        $node($temp) set Z_ 0


        $ns initial_node_pos $node($temp) 50

        $ns at 1.0 "$node($temp) setdest $x $y $node_speed"; #x,y,speed
    }
} 





# Traffic




set val(nf)         [lindex $argv 1]                ;# number of flows
set src [my_random $val(nn)]

for {set i 0} {$i < $val(nf)} {incr i} {
    # set src $i
    set dest [my_random $val(nn)]
    while {$src == $dest} {
       set dest [my_random $val(nn)] 
    }

    # Traffic config
    # create agent
    set tcp [new Agent/TCP/Vegas]
    $tcp set maxseq_ [lindex $argv 5]
    set tcp_sink [new Agent/TCPSink]
    # attach to nodes
    $ns attach-agent $node($src) $tcp
    $ns attach-agent $node($dest) $tcp_sink
    # connect agents
    $ns connect $tcp $tcp_sink
    $tcp set fid_ $i

    # Traffic generator
    set telnet [new Application/Telnet]
    # attach to agent
    $telnet attach-agent $tcp
    
    # start traffic generation
    $ns at 1.0 "$telnet start"


    # puts "-_-"
    # puts $src
    # puts $dest
}



# End Simulation

# Stop nodes
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns at 50.0 "$node($i) reset"
}

# call final function
proc finish {} {
    global ns trace_file nam_file
    $ns flush-trace
    close $trace_file
    close $nam_file
}

proc halt_simulation {} {
    global ns
    puts "Simulation ending"
    $ns halt
}

$ns at 150.0001 "finish"
$ns at 150.0002 "halt_simulation"



# Run simulation
puts "Simulation starting"
$ns run
#argument serial: nodes , flow, size , rows

