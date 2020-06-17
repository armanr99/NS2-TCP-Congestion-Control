#Create a simulator object
set ns [new Simulator]

#Open the nam file congestion.nam and the variable-trace file congestion.tr
set namfile [open congestion.nam w]
$ns namtrace-all $namfile
set tracefile [open congestion.tr w]
$ns trace-all $tracefile

#Define a 'finish' procedure
proc finish {} {
        global ns namfile tracefile
        $ns flush-trace
        close $namfile
        close $tracefile
        exit 0
}

#Create the network nodes
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]

#Create a duplex link between the nodes
$ns duplex-link $n1 $n3 100Mb 5ms DropTail
$ns duplex-link $n2 $n3 100Mb 5ms DropTail
$ns duplex-link $n3 $n4 100kb 1ms DropTail
$ns duplex-link $n4 $n5 100Mb 5ms DropTail
$ns duplex-link $n4 $n6 100Mb  5ms DropTail

#Set hints for nam
$ns duplex-link-op $n1 $n3 orient right-down
$ns duplex-link-op $n2 $n3 orient right-up
$ns duplex-link-op $n3 $n4 orient right
$ns duplex-link-op $n4 $n5 orient right-up
$ns duplex-link-op $n4 $n6 orient right-down
$ns duplex-link-op $n3 $n4 queuePos 0.5

#Set tcp sending agents
set tcp1 [new Agent/TCP/Reno]
$tcp1 set ttl_ 64
$ns attach-agent $n1 $tcp1

set tcp2 [new Agent/TCP/Reno]
$tcp2 set ttl_ 64
$ns attach-agent $n2 $tcp2

#Set tcp receiving agents
set sink1 [new Agent/TCPSink]
$ns attach-agent $n5 $sink1
set sink2 [new Agent/TCPSink]
$ns attach-agent $n6 $sink2

#Establish traffic between senders and sinks
$ns connect $tcp1 $sink1
$ns connect $tcp2 $sink2

#Run the simulation
$ns run