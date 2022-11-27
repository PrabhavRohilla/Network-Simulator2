set ns [new Simulator]
set nssim $ns
set simstart 0.0
set simend 30.0
set mxwnd 1000
set rng [new RNG]
set p [lindex $argv 0]
$rng seed 0

# $ns color 0 Blue
# $ns color 1 Red
# $ns color 2 Green
# $ns color 3 Orange

#Open the NAM trace file
set nf [open out.nam w]
$ns namtrace-all $nf

set outf [open out.txt w]

proc finish {} {
    global ns nf fmon_bn
    record_end
    puts "FINISHED"
    $ns flush-trace
    #Close the NAM trace file
    close $nf
    #Execute NAM on the trace file
    # exec nam out.nam &
    exit 0
}

source helper.tcl

set r [$ns node]
set d [$ns node]

#create bottleneck
$ns duplex-link $r $d 10mb 10ms DropTail
$ns queue-limit $r $d 1000
$ns duplex-link-op $r $d orient right

#create loss module
set loss_random_variable [new RandomVariable/Uniform]
$loss_random_variable set min_ 0 
$loss_random_variable set max_ 100

set loss_module [new ErrorModel] 
$loss_module drop-target [new Agent/Null]
#rate = p (in percentage)
$loss_module set rate_ $p
$loss_module ranvar $loss_random_variable 

$ns lossmodel $loss_module $r $d

#monitor for bottleneck
set fmon_bn [$ns makeflowmon Fid]
$ns attach-fmon [$ns link $r $d] $fmon_bn


for {set i 0} {$i < $nof_classes} {incr i} {
    set s($i) [$ns node]
    $ns duplex-link $s($i) $r 100mb [expr 10+30*$i]ms DropTail
    $ns queue-limit $s($i) $r 1000
    for {set j 0} {$j < $nof_tcps} {incr j} {

        set tcp [new Agent/TCP/Reno]
        $tcp set class_ 2
        $tcp set packetSize_ 1460
        $tcp set window_ $mxwnd
        $tcp set fid_ [expr $j+$nof_tcps*$i]
        $ns attach-agent $s($i) $tcp

        set sink [new Agent/TCPSink]
        $ns attach-agent $d $sink
        $ns connect $tcp $sink

        set ftp_local [new Application/FTP]
        $ftp_local attach-agent $tcp
        $ftp_local set type_ FTP

        set tcp_s($i,$j) $tcp
        set tcp_d($i,$j) $sink
        set ftp($i,$j) $ftp_local
        lappend freelist($i) $j
    }
}

$ns at $simstart "record_start"
for {set i 0} {$i<$nof_classes} {incr i} {
    $ns at $simstart "start_flow $i"
}
$ns at $simend "finish"

$ns run
