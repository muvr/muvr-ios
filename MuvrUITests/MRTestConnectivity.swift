import Foundation

struct MKConnectivity {

    static func send() {
        let port: mach_port_t = 9990

        var header: mach_msg_header_t = mach_msg_header_t()
        header.msgh_remote_port = port
        header.msgh_local_port = mach_port_t(MACH_PORT_NULL)
        header.msgh_bits = mach_msg_size_t(MACH_MSGH_BITS_ZERO)
        header.msgh_size = 0
        
        let error = mach_msg_send(&header)
        
        if (error == MACH_MSG_SUCCESS) {
            print(":(")
        } else {
            print(":)")
        }
    }
    
}
