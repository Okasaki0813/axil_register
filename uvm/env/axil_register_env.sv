`ifndef AXIL_REGISTER_ENV_SV
`define AXIL_REGISTER_ENV_SV

class axil_register_env extends uvm_env;

    `uvm_component_utils(axil_register_env)

    axil_register_master_agent      mst_agt;
    axil_register_slave_agent       slv_agt;

    axil_register_scoreboard        scb;
    axil_register_coverage          cov;

    axil_register_config            cfg;


    function new(string name = "axil_register_env", uvm_component parent = null);
        super.new(name, parent);        
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(axil_register_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "Configuration object not found!")
        end

        uvm_config_db#(axil_register_config)::set(this, "mst_agt", "cfg", cfg);
        uvm_config_db#(axil_register_config)::set(this, "slv_agt", "cfg", cfg);
    
        if(cfg.has_master) begin
            mst_agt = axil_register_master_agent::type_id::create("mst_agt", this);
        end
        if(cfg.has_slave) begin
            slv_agt = axil_register_slave_agent::type_id::create("slv_agt", this);
        end

        if(cfg.enable_scb) begin
            scb = axil_register_scoreboard::type_id::create("scb", this);
        end

        if(cfg.enable_cov) begin
            cov = axil_register_coverage::type_id::create("cov", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if(cfg.enable_scb) begin
            if(cfg.has_master) begin
                mst_agt.ap.connect(scb.mst_fifo.analysis_export);  // 改个名字
            end
            if(cfg.has_slave) begin
                slv_agt.ap.connect(scb.slv_fifo.analysis_export);   // 改个名字
            end
        end

        if(cfg.enable_cov && cfg.has_master) begin
            mst_agt.ap.connect(cov.analysis_export);
        end
    endfunction
    
endclass

`endif // AXIL_REGISTER_ENV_SV