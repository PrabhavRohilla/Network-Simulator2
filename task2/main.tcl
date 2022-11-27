set ns [new Simulator]
set nssim $ns
set simstart 0.0
set simend 50.0
set mxwnd 1000
set rho [lindex $argv 0]
set rng [new RNG]
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

set r1 [$ns node]
set r2 [$ns node]

#create bottleneck
$ns duplex-link $r1 $r2 10mb 30ms DropTail
$ns queue-limit $r1 $r2 100
$ns duplex-link-op $r1 $r2 orient right

#monitor for bottleneck
set fmon_bn [$ns makeflowmon Fid]
$ns attach-fmon [$ns link $r1 $r2] $fmon_bn


for {set i 0} {$i < $nof_classes} {incr i} {
    #core links
    set c1($i) [$ns node]
    $ns duplex-link $c1($i) $r1 100mb [expr 5+15*$i]ms DropTail
    $ns queue-limit $c1($i) $r1 100
    set c2($i) [$ns node]
    $ns duplex-link $c2($i) $r2 100mb [expr 5+15*$i]ms DropTail
    $ns queue-limit $c2($i) $r2 100

    for {set j 0} {$j < $nof_access} {incr j} {
        #access links
        set s($i,$j) [$ns node]
        $ns duplex-link $s($i,$j) $c1($i) 10mb 10ms DropTail
        $ns queue-limit $s($i,$j) $c1($i) 100
        set d($i,$j) [$ns node]
        $ns duplex-link $d($i,$j) $c2($i) 10mb 10ms DropTail
        $ns queue-limit $d($i,$j) $c2($i) 100

            for {set k 0} {$k < [expr $nof_tcps/$nof_access]} {incr k} {
                set tcpnum [expr $k + $nof_tcps*$j/$nof_access]
                set tcp [new Agent/TCP/Reno]
                $tcp set class_ 2
                $tcp set packetSize_ 1460
                $tcp set window_ $mxwnd
                $tcp set fid_ [expr $tcpnum+$nof_tcps*$i]
                $ns attach-agent $s($i,$j) $tcp

                set sink [new Agent/TCPSink]
                $ns attach-agent $d($i,$j) $sink
                $ns connect $tcp $sink

                set ftp_local [new Application/FTP]
                $ftp_local attach-agent $tcp
                $ftp_local set type_ FTP

                set tcp_s($i,$tcpnum) $tcp
                set tcp_d($i,$tcpnum) $sink
                set ftp($i,$tcpnum) $ftp_local
                lappend freelist($i) $tcpnum
            }
    }
}

$ns at $simstart "record_start"
for {set i 0} {$i<$nof_classes} {incr i} {
    $ns at $simstart "start_flow $i"
}
$ns at $simend "finish"

$ns run
