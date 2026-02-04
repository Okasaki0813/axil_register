`ifndef AXIL_REGISTER_SEQ_PKG_SV
`define AXIL_REGISTER_SEQ_PKG_SV

package axil_register_seq_pkg;
    import uvm_pkg::*;

    import axil_register_vip_pkg::*;
    import axil_register_env_pkg::*;  // 依赖环境（访问virtual sequencer）
    
    `include "uvm_macros.svh"
    
    // 基础序列
    `include "axil_register_base_virtual_sequence.sv"
    `include "axil_register_sequence.sv"
    
    // 功能序列
    `include "axil_register_read_seq.sv"
    `include "axil_register_write_seq.sv"
    
    `include "axil_register_smoke_seq.sv"
    
    // 虚拟序列
    // `include "axil_register_smoke_virt_seq.sv"
    // `include "axil_register_reset_virt_seq.sv"
    // `include "axil_register_random_virt_seq.sv"
    // `include "axil_register_ral_virt_seq.sv"
    // `include "axil_register_ral_field_virt_seq.sv"
    // `include "axil_register_addr_decode_virt_seq.sv"
    // `include "axil_register_wstrb_virt_seq.sv"
endpackage

`endif // AXIL_REGISTER_SEQ_PKG_SV