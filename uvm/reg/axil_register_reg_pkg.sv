`ifndef AXIL_REGISTER_REG_PKG_SV
`define AXIL_REGISTER_REG_PKG_SV

package axil_register_reg_pkg;
    import uvm_pkg::*;
    import axil_register_vip_pkg::*;
    
    `include "uvm_macros.svh"
    
    `include "axil_register_reg_data.sv"
    `include "axil_register_reg_block.sv"
endpackage

`endif // AXIL_REGISTER_REG_PKG_SV