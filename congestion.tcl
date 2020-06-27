#Get tcp congestion algorithm name from input
if { $argc != 1 } {
   puts "The congestion.tcl script requires tcp congestion alogirthm name as input"
   puts "For example, ns congestion.tcl Newreno"
   puts "Please try again."
} else {
   if { [lindex $argv 0] == "Tahoe" } {
      set CONGESTION_ALGORITHM "TCP"
   } else {
      set CONGESTION_ALGORITHM "TCP/[lindex $argv 0]"
   }
}

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
set tcp1 [new Agent/$CONGESTION_ALGORITHM]
$tcp1 set ttl_ 64
$tcp1 set fid_ 1
$ns attach-agent $n1 $tcp1

set tcp2 [new Agent/$CONGESTION_ALGORITHM]
$tcp2 set ttl_ 64
$tcp2 set fid_ 2
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

set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2

$ns at 0.0 "$ftp1 start"
$ns at 0.0 "$ftp2 start"
$ns at 1000.0 "$ftp1 stop"
$ns at 1000.0 "$ftp2 stop"
$ns at 1000.0 "finish"

#Plot cwnd data
proc plotCwnd {tcpSource outfile} {
   global ns
   set now [$ns now]
   set cwnd_ [$tcpSource set cwnd_]

   puts  $outfile  "$now,$cwnd_"
   $ns at [expr $now + 1] "plotCwnd $tcpSource $outfile"
}

set cwndTcp1File [open "cwnd1.csv" w]
set cwndTcp2File [open "cwnd2.csv" w]
puts  $cwndTcp1File  "time,cwnd"
puts  $cwndTcp2File  "time,cwnd"
$ns at 0.0  "plotCwnd $tcp1 $cwndTcp1File"
$ns at 0.0  "plotCwnd $tcp2 $cwndTcp2File"

#Plot goodput data
proc plotGoodput {tcpSource prevAck outfile} {
   global ns
   set now [$ns now]
   set ack [$tcpSource set ack_]

   puts  $outfile  "$now,[expr ($ack - $prevAck) * 8]"
   $ns at [expr $now + 1] "plotGoodput $tcpSource $ack $outfile"
}

set goodputTcp1File [open "goodput1.csv" w]
set goodputTcp2File [open "goodput2.csv" w]
puts  $goodputTcp1File  "time,goodput"
puts  $goodputTcp2File  "time,goodput"
$ns at 0.0  "plotGoodput $tcp1 0 $goodputTcp1File"
$ns at 0.0  "plotGoodput $tcp2 0 $goodputTcp2File"

#Plot RTT data
proc plotRTT {tcpSource outfile} {
   global ns
   set now [$ns now]
   set rtt_ [$tcpSource set rtt_]

   puts  $outfile  "$now,$rtt_"
   $ns at [expr $now + 1] "plotRTT $tcpSource $outfile"
}

set rttTcp1File [open "rtt1.csv" w]
set rttTcp2File [open "rtt2.csv" w]
puts  $rttTcp1File  "time,rtt"
puts  $rttTcp2File  "time,rtt"
$ns at 0.0  "plotRTT $tcp1 $rttTcp1File"
$ns at 0.0  "plotRTT $tcp2 $rttTcp2File"

#Run the simulation
$ns run