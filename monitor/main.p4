#include "tables.p4"

//microsecond, 3s
#define timestamp_window_max 3000000

control ingress {
	
	if (standard_metadata.ingress_port != 1) { // from proxy to client
        apply(table_forward_back);
    } else { // from client to proxy
        if (ethernet.etherType == ETHERTYPE_IPV4 and valid(ipv4)) { // ipv4
            // monitor
		    
		    // init
			apply(table_count_min_sketch_init);
		
			// timestamp
			apply(table_get_last_timestamp);
			if(my_metadata.timestamp0 + timestamp_window_max < intrinsic_metadata.ingress_global_timestamp){
				apply(table_register0_reset);
			}
			if(my_metadata.timestamp1 + timestamp_window_max < intrinsic_metadata.ingress_global_timestamp){
				apply(table_register1_reset);
			}
			if(my_metadata.timestamp2 + timestamp_window_max < intrinsic_metadata.ingress_global_timestamp){
				apply(table_register2_reset);
			}
			apply(table_update_timestamp);
		
			// process
			apply(table_count_min_sketch_incr);
			if(my_metadata.count_val0 > heavy_hitter_max and
			   my_metadata.count_val1 > heavy_hitter_max and
			   my_metadata.count_val2 > heavy_hitter_max) {
				apply(table_count_min_sketch_decr);
				apply(table_drop);
			} else{
			  apply(table_forward_ahead_ipv4);
			}
        } else if (ethernet.etherType == ETHERTYPE_ARP_IPV4 and valid(arp_ipv4)) {  // arp
	      apply(table_forward_ahead_arp_ipv4);
        } else {  // for now, don't care
            apply(table_drop); 
        }
    }
}

control egress {
}
