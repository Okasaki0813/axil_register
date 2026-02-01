`ifndef AXIL_REGISTER_WSTRB_TEST_SV
`define AXIL_REGISTER_WSTRB_TEST_SV

class axil_register_wstrb_test extends axil_register_base_test;
    `uvm_component_utils(axil_register_wstrb_test)

    function new(string name = "axil_register_wstrb_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axil_register_wstrb_virt_seq vseq = axil_register_wstrb_virt_seq::type_id::create("vseq");
        phase.raise_objection(this);
        vseq.start(env.virt_sqr);
        #100ns; 
        phase.drop_objection(this);
    endtask
endclass

`endif // AXIL_REGISTER_WSTRB_TEST_SV