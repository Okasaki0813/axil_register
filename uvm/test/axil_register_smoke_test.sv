class axil_register_smoke_test extends axil_register_base_test;
    `uvm_component_utils(axil_register_smoke_test)
    
    function new(string name = "axil_register_smoke_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        axil_register_smoke_virt_seq vseq = axil_register_smoke_virt_seq::type_id::create("vseq");
        phase.raise_objection(this);
        vseq.start(env.virt_sqr);
        phase.drop_objection(this);
    endtask
endclass