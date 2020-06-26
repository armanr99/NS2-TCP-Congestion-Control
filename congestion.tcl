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

#Create a random generator
set rng [new RNG]
$rng seed 0

#Create random delay variables
set n2_n3_delay [new RandomVariable/Uniform]
$n2_n3_delay set min_ 5
$n2_n3_delay set max_ 25
$n2_n3_delay use-rng $rng

set n4_n6_delay [new RandomVariable/Uniform]
$n4_n6_delay set min_ 5
$n4_n6_delay set max_ 25
$n4_n6_delay use-rng $rng

#Create a duplex link between the nodes
$ns duplex-link $n1 $n3 100Mb 5ms DropTail
$ns duplex-link $n2 $n3 100Mb [expr [$n2_n3_delay value]]ms DropTail
$ns duplex-link $n3 $n4 100kb 1ms DropTail
$ns duplex-link $n4 $n5 100Mb 5ms DropTail
$ns duplex-link $n4 $n6 100Mb [expr [$n4_n6_delay value]]ms DropTail

#Set hints for nam
$ns duplex-link-op $n1 $n3 orient right-down
$ns duplex-link-op $n2 $n3 orient right-up
$ns duplex-link-op $n3 $n4 orient right
$ns duplex-link-op $n4 $n5 orient right-up
$ns duplex-link-op $n4 $n6 orient right-down
$ns duplex-link-op $n3 $n4 queuePos 0.5

#Set queue sizes
$ns queue-limit $n3 $n1 10
$ns queue-limit $n3 $n2 10
$ns queue-limit $n3 $n4 10
$ns queue-limit $n4 $n3 10
$ns queue-limit $n4 $n5 10
$ns queue-limit $n4 $n5 10
$ns queue-limit $n4 $n6 10

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

#Schedule the connections data flow
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ns at 0.0 "$ftp1 start"

set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
$ns at 0.0 "$ftp2 start"

$ns at 1000.0 "finish"

#Run the simulation
$ns run