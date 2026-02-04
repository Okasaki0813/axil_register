`ifndef AXIL_REGISTER_SMOKE_TEST_SV
`define AXIL_REGISTER_SMOKE_TEST_SV

class axil_register_smoke_test extends axil_register_base_test;
    
    `uvm_component_utils(axil_register_smoke_test)
    
    function new(string name = "axil_register_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "Starting smoke test", UVM_LOW)

        #1000;

        if (cfg.enable_scb) begin
            env.scb.report();
        end

        `uvm_info(get_type_name(), "Smoke test completed", UVM_LOW)
        
        phase.drop_objection(this);
    endtask

endclass

`endif // AXIL_REGISTER_SMOKE_TEST_SV