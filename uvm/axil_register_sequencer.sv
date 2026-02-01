`ifndef AXIL_REGISTER_SEQUENCER_SV
`define AXIL_REGISTER_SEQUENCER_SV

`include "uvm_macros.svh"

class axil_register_sequencer extends uvm_sequencer #(axil_register_transaction);
    `uvm_component_utils(axil_register_sequencer)

    function new(string name = "axil_register_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

`endif // AXIL_REGISTER_SEQUENCER_SV