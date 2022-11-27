#This code contains methods for flow generation and result recording.

# the total (theoretical) load in the bottleneck link
set rho 0.8
puts "rho = $rho"

# Filetransfer parameters
set mfsize 500
set mpktsize 1460

# bottleneck bandwidth, required for setting the load
set bnbw 10000000
set nof_tcps 100
set nof_classes 4
set rho_cl [expr $rho/$nof_classes]
puts "rho_cl=$rho_cl, nof_classes=$nof_classes"
set mean_intarrtime [expr ($mpktsize+40)*8.0*$mfsize/($bnbw*$rho_cl)]

#flow interarrival time
puts "1/la = $mean_intarrtime"

for {set ii 0} {$ii < $nof_classes} {incr ii} {
    #contains the delay results for each class
    set delres($ii) {}
    #contains the number of active flows as a function of time
    set nlist($ii) {} 
    #contains the free flows
    set freelist($ii) {}
    #contains information of the reserved flows 
    set reslist($ii) {}
}
Agent/TCP instproc done {} {
    global nssim freelist reslist ftp rng mfsize mean_intarrtime nof_tcps simstart simend delres nlist
    #the global variables nssim (ns simulator instance), ftp (application),
    #rng (random number generator), simstart (start time of the simulation) and
    #simend (ending time of the simulation) have to be created by the user in
    #the main program
    #flow-ID of the TCP flow
    set flind [$self set fid_]
    #the class is determined by the flow-ID and total number of tcp-sources
    set class [expr int(floor($flind/$nof_tcps))]
    set ind [expr $flind-$class*$nof_tcps]
    # puts "Flow of class: $class, flow id:$flind"
    # puts "reserved flows:[llength $reslist($class)]"
    lappend nlist($class) [list [$nssim now] [llength $reslist($class)]]
    
    for {set nn 0} {$nn < [llength $reslist($class)]} {incr nn} {
        set tmp [lindex $reslist($class) $nn]
        set tmpind [lindex $tmp 0]
        if {$tmpind == $ind} {
            set mm $nn
            set starttime [lindex $tmp 1]
            set fsize [lindex $tmp 2]
        }
    }
    set reslist($class) [lreplace $reslist($class) $mm $mm]
    lappend freelist($class) $ind
    set tt [$nssim now]
    if {$starttime > $simstart && $tt < $simend} {
        puts "flow class: $class, time: [expr $tt-$starttime], file size: $fsize"
        lappend delres($class) [expr $tt-$starttime]
    }
    if {$tt > $simend} {
        $nssim at $tt "$nssim halt"
    }
}
proc start_flow {class} {
    global nssim freelist reslist ftp tcp_s tcp_d rng nof_tcps mfsize mean_intarrtime simend
    #you have to create the variables tcp_s (tcp source) and tcp_d (tcp
    #destination)
    set tt [$nssim now]
    set freeflows [llength $freelist($class)]
    set resflows [llength $reslist($class)]
    lappend nlist($class) [list $tt $resflows]
    if {$freeflows == 0} {
        puts "Class $class: At $tt, nof of free TCP sources == 0!!!"
        # puts "reslist($class)=$reslist($class)"
        return
    }
    #take the first index from the list of free flows
    set ind [lindex $freelist($class) 0]
    set cur_fsize [expr ceil([$rng exponential $mfsize])]
    $tcp_s($class,$ind) reset
    $tcp_d($class,$ind) reset
    $ftp($class,$ind) produce $cur_fsize
    set freelist($class) [lreplace $freelist($class) 0 0]
    lappend reslist($class) [list $ind $tt $cur_fsize]
    set newarrtime [expr $tt+[$rng exponential $mean_intarrtime]]
    $nssim at $newarrtime "start_flow $class"
    if {$tt > $simend} {
        $nssim at $tt "$nssim halt"
    }
    # puts "Created flow with id: [expr $ind+$class], for class: $class"
    # puts "free:$freelist($class), reserved: $reslist($class)"
}
set parr_start 0
set pdrops_start 0
proc record_start {} {
    global fmon_bn nssim parr_start pdrops_start nof_classes
    #you have to create the fmon_bn (flow monitor) in the bottleneck link
    set parr_start [$fmon_bn set parrivals_]
    set pdrops_start [$fmon_bn set pdrops_]
    puts "Bottleneck at [$nssim now]: arr=$parr_start, drops=$pdrops_start"
}
set parr_end 0
set pdrops_end 0
proc record_end { } {
    global fmon_bn nssim parr_start pdrops_start nof_classes delres outf
    set parr_start [$fmon_bn set parrivals_]
    set pdrops_start [$fmon_bn set pdrops_]
    puts "Bottleneck at [$nssim now]: arr=$parr_start, drops=$pdrops_start"
    for {set class 0} {$class < $nof_classes} {incr class} {
        set sum 0
        set n [llength $delres($class)]
        puts $outf "$n $delres($class)"
        for {set i 0} {$i < $n} {incr i} {
            set ti [lindex $delres($class) $i]
            set sum [expr $sum+$ti]
        }
        if {$sum == 0} {
            puts "No files sent for class $class"
            continue
        }
        set avg [expr $sum/$n]
        puts "Average transfer time for class $class: $avg"
    }
}