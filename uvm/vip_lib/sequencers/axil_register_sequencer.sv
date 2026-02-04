`ifndef AXIL_REGISTER_SEQUENCER_SV
`define AXIL_REGISTER_SEQUENCER_SV

class axil_register_sequencer extends uvm_sequencer #(axil_register_transaction);
    `uvm_component_utils(axil_register_sequencer)

    function new(string name = "axil_register_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask
endclass

`endif // AXIL_REGISTER_SEQUENCER_SV