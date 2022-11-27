
# basic1.tcl simulation: A---R---B

#Create a simulator object
set ns [new Simulator]


#Open the nam file basic1.nam and the variable-trace file basic1.tr
set namfile [open basic1.nam w]
$ns namtrace-all $namfile
set tracefile [open basic1.tr w]
$ns trace-all $tracefile


set rng [new RNG]

#random no generator

# set rng [new RandomVariable/Exponential]

# $rng use-rng $rand1

# $rng set avg_ 5



#simstart and sim end variables
set simstart "0.0"
set simend "10.0"
set mpktsize 1460


#This code contains methods for flow generation and result recording.

# the total (theoretical) load in the bottleneck link

set rho 0.8
puts "rho = $rho"

# Filetransfer parameters
set mfsize 500

# bottleneck bandwidth, required for setting the load
set bnbw 10000000
set nof_tcps 100 

#maximum number of tcps
set nof_classes 4 

#number of RTT classes
set rho_cl [expr $rho/$nof_classes] 

#load divided evenly between RTT classes
puts "rho_cl=$rho_cl, nof_classes=$nof_classes"
set mean_intarrtime [expr ($mpktsize+40)*8.0*$mfsize/($bnbw*$rho_cl)]

#flow interarrival time
puts "1/la = $mean_intarrtime"
for {set ii 0} {$ii < $nof_classes} {incr ii} {
    set delres($ii) {} 
    #contains the delay results for each class
    set nlist($ii) {} 
    #contains the number of active flows as a function of time
    set freelist($ii) {} 
    #contains the free flows
    set reslist($ii) {} 
    #contains information of the reserved flows
}



Agent/TCP/Reno instproc done {} {

    puts "pskmc"
    global ns freelist reslist ftp rng mfsize mean_intarrtime nof_tcps simstart simend delres nlist
    
    #the global variables ns (ns simulator instance), ftp (application),
    
    #rng (random number generator), simstart (start time of the simulation) and
    
    #simend (ending time of the simulation) have to be created by the user in
    
    #the main program
    
    #flow-ID of the TCP flow
    set flind [$self set fid_]
    
    #the class is determined by the flow-ID and total number of tcp-sources
    set class [expr int(floor($flind/$nof_tcps))]
    set ind [expr $flind-$class*$nof_tcps]
    lappend nlist($class) [list [$ns now] [llength $reslist($class)]]
    for {set nn 0} {$nn < [llength $reslist($class)]} {incr nn} {
        set tmp [lindex $reslist($class) $nn]
        set tmpind [lindex $tmp 0]
        if {$tmpind == $ind} {
            set mm $nn
            set starttime [lindex $tmp 1]
        }
    }
    set reslist($class) [lreplace $reslist($class) $mm $mm]
    lappend freelist($class) $ind
    set tt [$ns now]
    if {$starttime > $simstart && $tt < $simend} {
        lappend delres($class) [expr $tt-$starttime]
    }
    if {$tt > $simend} {
        $ns at $tt "$ns halt"
    }
}




#Define a 'finish' procedure
proc finish {} {
        global ns namfile tracefile
        $ns flush-trace
        close $namfile
        close $tracefile
        exit 0
}


#Create the network nodes
set s1 [$ns node]
set s2 [$ns node]
set s3 [$ns node]
set s4 [$ns node]
set R [$ns node]
set D [$ns node]



#setting labels
$s1 label "s1"
$s2 label "s2"
$s3 label "s3"
$s4 label "s4"


#Create a duplex link between the nodes

$ns duplex-link $s1 $R 100Mb 10ms DropTail
$ns duplex-link $s2 $R 100Mb 10ms DropTail
$ns duplex-link $s3 $R 100Mb 10ms DropTail
$ns duplex-link $s4 $R 100Mb 10ms DropTail
$ns duplex-link $R $D 10Mb 10ms DropTail



#settting queue limits
$ns queue-limit $s1 $R 1000
$ns queue-limit $s2 $R 1000
$ns queue-limit $s3 $R 1000
$ns queue-limit $s4 $R 1000





# The queue size at $R is to be 1000, including the packet being sent
$ns queue-limit $R $D 1000


# some hints for nam

# color packets of flow 0 red
$ns color 0 Red
$ns color 1 Red
$ns color 2 Red
$ns color 3 Red

$ns duplex-link-op $s1 $R orient bottom
$ns duplex-link-op $s2 $R orient right-up
$ns duplex-link-op $s3 $R orient right-down
$ns duplex-link-op $s4 $R orient down
$ns duplex-link-op $R $D orient right
$ns duplex-link-op $R $D queuePos 0.5


#Create a TCP receive agent (a traffic sink) and attach it to D
set end0 [new Agent/TCPSink]
$ns attach-agent $D $end0


# Create a TCP sending agent and attach it to 

# set tcp_s { }
# set tcp_d { }

set tcp_s(0) [new Agent/TCP/Reno]
set tcp_s(1) [new Agent/TCP/Reno]
set tcp_s(2) [new Agent/TCP/Reno]
set tcp_s(3) [new Agent/TCP/Reno]

set tcp_d(0) [new Agent/TCPSink]
set tcp_d(1) [new Agent/TCPSink]
set tcp_d(2) [new Agent/TCPSink]
set tcp_d(3) [new Agent/TCPSink]


$ns attach-agent $s1 $tcp_s(0)
$ns attach-agent $s2 $tcp_s(1)
$ns attach-agent $s3 $tcp_s(2)
$ns attach-agent $s4 $tcp_s(3)

$ns attach-agent $D $tcp_d(0)
$ns attach-agent $D $tcp_d(1)
$ns attach-agent $D $tcp_d(2)
$ns attach-agent $D $tcp_d(3)

#$tcp_s(0) set class_ 0
#$tcp_s(0) set window_ 1000
#$tcp_s(0) packetSize_ 1460
 
for {set i 0} {$i < 4} {incr i} {
    #set tcp_s($i) [new Agent/TCP/Reno]

    #lappend tcp_s [new Agent/TCP/Reno]

    

    $tcp_s($i) set class_ $i
    $tcp_s($i) set window_ 1000
    $tcp_s($i) set packetSize_ 1460
    $tcp_s($i) set fid_ $i


    #set tcp_d($i) end0

    #lappend tcp_d end0

    #Something is over here
    #puts "Am i over here"
    $ns connect $tcp_s($i) $tcp_d($i)
}

# set tcp0 [new Agent/TCP/Reno]
# $tcp0 set class_ 0
# $tcp0 set window_ 1000
# $tcp0 set packetSize_ 1460


# set tcp1 [new Agent/TCP/Reno]

# $tcp1 set class_ 1

# $tcp1 set window_ 1000

# $tcp1 set packetSize_ 1460


# set tcp2 [new Agent/TCP/Reno]

# $tcp2 set class_ 2

# $tcp2 set window_ 1000

# $tcp2 set packetSize_ 1460


# set tcp3 [new Agent/TCP/Reno]

# $tcp3 set class_ 3

# $tcp3 set window_ 1000

# $tcp3 set packetSize_ 1460





# Let's trace some variables
# $tcp0 attach $tracefile
# $tcp0 tracevar cwnd_
# $tcp0 tracevar ssthresh_
# $tcp0 tracevar ack_
# $tcp0 tracevar maxseq_


# $tcp1 attach $tracefile

# $tcp1 tracevar cwnd_

# $tcp1 tracevar ssthresh_

# $tcp1 tracevar ack_

# $tcp1 tracevar maxseq_






#Connect the traffic source with the traffic sink
# $ns connect $tcp0 $end0

# $ns connect $tcp1 $end0

# $ns connect $tcp2 $end0

# $ns connect $tcp3 $end0



# create a random variable that follows the uniform distribution
set loss_random_variable [new RandomVariable/Uniform]
$loss_random_variable set min_ 0 

# the range of the random variable;
$loss_random_variable set max_ 100

set loss_module [new ErrorModel]
$loss_module drop-target [new Agent/Null] 

#a null agent where the dropped packets go to
$loss_module set rate_ 10 

# error rate will then be (0.1 = 10 / (100 - 0));
$loss_module ranvar $loss_random_variable 

# attach the random variable to loss module;

$ns lossmodel $loss_module $R $D


#Schedule the connection data flow; start sending data at T=0, stop at T=10.0
#set ftp { }

# set ftp(0) [new Application/FTP]
# set ftp(1) [new Application/FTP]
# set ftp(2) [new Application/FTP]
# set ftp(3) [new Application/FTP]


#some modifications
set ftp(0) [new Application/Traffic/Exponential]
#$ftp(0) set packetSize_ 210
$ftp(0) set burst_time_ 0
$ftp(0) set idle_time_ 500ms
$ftp(0) set rate_ 10000k

set ftp(1) [new Application/Traffic/Exponential]
#$ftp(1) set packetSize_ 210
$ftp(1) set burst_time_ 0
$ftp(1) set idle_time_ 500ms
$ftp(1) set rate_ 10000k

set ftp(2) [new Application/Traffic/Exponential]
#$ftp(2) set packetSize_ 210
$ftp(2) set burst_time_ 0
$ftp(2) set idle_time_ 500ms
$ftp(2) set rate_ 10000k

set ftp(3) [new Application/Traffic/Exponential]
#$ftp(3) set packetSize_ 210
$ftp(3) set burst_time_ 0
$ftp(3) set idle_time_ 500ms
$ftp(3) set rate_ 10000k

#######





for {set i 0} {$i < 4} {incr i} {
    #set ftp($i) ftp [new Application/FTP]

    #lappend ftp [new Application/FTP]
    $ftp($i) attach-agent $tcp_s($i)
}


# set ftp [new Application/FTP]
# $ftp attach-agent $tcp0

# $ns at 0.0 "$myftp0 start"

for { set i 0 } {$i<4} {incr i} {
    $ns at 0.0 "start_flow $i"
}
# $ns at 0.0 "start_flow 0"


# set rng [new RNG]

# #random no generator

# # set rng [new RandomVariable/Exponential]

# # $rng use-rng $rand1

# # $rng set avg_ 5



# #simstart and sim end variables
# set simstart "0.0"
# set simend "10.0"
# set mpktsize 1460


# #This code contains methods for flow generation and result recording.

# # the total (theoretical) load in the bottleneck link

# set rho 0.8
# puts "rho = $rho"

# # Filetransfer parameters
# set mfsize 500

# # bottleneck bandwidth, required for setting the load
# set bnbw 10000000
# set nof_tcps 100 

# #maximum number of tcps
# set nof_classes 4 

# #number of RTT classes
# set rho_cl [expr $rho/$nof_classes] 

# #load divided evenly between RTT classes
# puts "rho_cl=$rho_cl, nof_classes=$nof_classes"
# set mean_intarrtime [expr ($mpktsize+40)*8.0*$mfsize/($bnbw*$rho_cl)]

# #flow interarrival time
# puts "1/la = $mean_intarrtime"
# for {set ii 0} {$ii < $nof_classes} {incr ii} {
#     set delres($ii) {} 
#     #contains the delay results for each class
#     set nlist($ii) {} 
#     #contains the number of active flows as a function of time
#     set freelist($ii) {} 
#     #contains the free flows
#     set reslist($ii) {} 
#     #contains information of the reserved flows
# }



# Agent/TCP/Reno instproc done {} {

#     puts "pskmc"
#     global ns freelist reslist ftp rng mfsize mean_intarrtime nof_tcps simstart
#     simend delres nlist
    
#     #the global variables ns (ns simulator instance), ftp (application),
    
#     #rng (random number generator), simstart (start time of the simulation) and
    
#     #simend (ending time of the simulation) have to be created by the user in
    
#     #the main program
    
#     #flow-ID of the TCP flow
#     set flind [$self set fid_]-
    
#     #the class is determined by the flow-ID and total number of tcp-sources
#     set class [expr int(floor($flind/$nof_tcps))]
#     set ind [expr $flind-$class*$nof_tcps]
#     lappend nlist($class) [list [$ns now] [llength $reslist($class)]]
#     for {set nn 0} {$nn < [llength $reslist($class)]} {incr nn} {
#         set tmp [lindex $reslist($class) $nn]
#         set tmpind [lindex $tmp 0]
#         if {$tmpind == $ind} {
#             set mm $nn
#             set starttime [lindex $tmp 1]
#         }
#     }
#     set reslist($class) [lreplace $reslist($class) $mm $mm]
#     lappend freelist($class) $ind
#     set tt [$ns now]
#     if {$starttime > $simstart && $tt < $simend} {
#         lappend delres($class) [expr $tt-$starttime]
#     }
#     if {$tt > $simend} {
#         $ns at $tt "$ns halt"
#     }
# }


proc start_flow {class} {

    puts "$class\n"

    global ns freelist reslist ftp rng nof_tcps mfsize mean_intarrtime simend
    
    #you have to create the variables tcp_s (tcp source) and ($tcp_d) (tcp destination)
    set tt [$ns now]
    set freeflows [llength $freelist($class)]
    set resflows [llength $reslist($class)]
    lappend nlist($class) [list $tt $resflows]
    if {$freeflows == 0} {
        puts "Class $class: At $tt, nof of free TCP sources == 0!!!"
        puts "freelist($class)=$freelist($class)"
        puts "reslist($class)=$reslist($class)"
        exit
    }

    
    #take the first index from the list of free flows
    set ind [lindex $freelist($class) 0]
    set cur_fsize [expr ceil([$rng exponential $mfsize])]
    $($tcp_s)($class,$ind) reset
    $($tcp_d)($class,$ind) reset
    $ftp($class,$ind) produce $cur_fsize
    set freelist($class) [lreplace $freelist($class) 0 0]
    lappend reslist($class) [list $ind $tt $cur_fsize]
    set newarrtime [expr $tt+[$rng exponential $mean_intarrtime]]
    $ns at $newarrtime "start_flow $class"
    if {$tt > $simend} {
        $ns at $tt "$ns halt"
    }
}


# set parr_start 0
# set pdrops_start 0
# proc record_start {} {
#     global fmon_bn ns parr_start pdrops_start nof_classes
    
#     #you have to create the fmon_bn (flow monitor) in the bottleneck link
#     set parr_start [$fmon_bn set parrivals_]
#     set pdrops_start [$fmon_bn set pdrops_]
#     puts "Bottleneck at [$ns now]: arr=$parr_start, drops=$pdrops_start"
# }


# set parr_end 0
# set pdrops_end 0
# proc record_end { } {
#     global fmon_bn ns parr_start pdrops_start nof_classes
#     set parr_start [$fmon_bn set parrivals_]
#     set pdrops_start [$fmon_bn set pdrops_]
#     puts "Bottleneck at [$ns now]: arr=$parr_start, drops=$pdrops_start"
# }



#Run the simulation
$ns run