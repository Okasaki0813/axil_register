`ifndef AXIL_REGISTER_ENV_PKG_SV
`define AXIL_REGISTER_ENV_PKG_SV

package axil_register_env_pkg;
    import uvm_pkg::*;
    import axil_register_vip_pkg::*;
    import axil_register_reg_pkg::*;
    
    `include "uvm_macros.svh"
    
    // `include "axil_register_virtual_sequencer.sv"

    // `include "axil_register_reg_adapter.sv"
    // `include "axil_register_reg_predictor.sv"

    `include "axil_register_scoreboard.sv"

    `include "axil_register_env.sv"
endpackage

`endif // AXIL_REGISTER_ENV_PKG_SV