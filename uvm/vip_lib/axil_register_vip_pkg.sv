`ifndef AXIL_REGISTER_VIP_PKG_SV
`define AXIL_REGISTER_VIP_PKG_SV

package axil_register_vip_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "cfg/axil_register_config.sv"

    `include "transactions/axil_register_transaction.sv"
    
    `include "drivers/axil_register_base_driver.sv"
    `include "monitors/axil_register_monitor.sv"
    `include "sequencers/axil_register_sequencer.sv"
    `include "agents/axil_register_base_agent.sv"
    
    `include "drivers/axil_register_master_driver.sv"
    `include "agents/axil_register_master_agent.sv"

    `include "drivers/axil_register_slave_driver.sv"
    `include "agents/axil_register_slave_agent.sv"
endpackage
`endif // AXIL_REGISTER_VIP_PKG_SV