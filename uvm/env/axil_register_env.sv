`ifndef AXIL_REGISTER_ENV_SV
`define AXIL_REGISTER_ENV_SV

`include "uvm_macros.svh"

class axil_register_env extends uvm_env;
    `uvm_component_utils(axil_register_env)

    axil_register_agent             agt;
    axil_register_agent             slv_agt;
    axil_register_scoreboard        scb;
    axil_register_coverage          cov;
    axil_register_virtual_sequencer virt_sqr;

    axil_register_reg_block         rm;      
    axil_register_reg_adapter       adapter;

    axil_register_config cfg;

    uvm_reg_predictor #(axil_register_transaction) reg_predictor;

    function new(string name = "axil_register_env", uvm_component parent);
        super.new(name, parent);        
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(axil_register_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("NOCFG", "无法从 config_db 获取 axil_register_config！")
        end

        uvm_config_db#(axil_register_config)::set(this, "agt*", "cfg", cfg);
        uvm_config_db#(axil_register_config)::set(this, "slv_agt*", "cfg", cfg);
    
        agt = axil_register_agent::type_id::create("agt", this);
        slv_agt = axil_register_agent::type_id::create("slv_agt", this);
        virt_sqr = axil_register_virtual_sequencer::type_id::create("virt_sqr", this);

        if(cfg.enable_scb) begin
            scb = axil_register_scoreboard::type_id::create("scb", this);
        end

        if(cfg.enable_cov) begin
            cov = axil_register_coverage::type_id::create("cov", this);
        end

        rm = axil_register_reg_block::type_id::create("rm", this);
        rm.build();
        adapter = axil_register_reg_adapter::type_id::create("adapter", this);
        reg_predictor = uvm_reg_predictor#(axil_register_transaction)::type_id::create("reg_predictor", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // 将模型通过适配器连接到 Master Agent 的 Sequencer 上
        rm.default_map.set_sequencer(agt.sqr, adapter);

        // 设置基地址（可选，如果你 RTL 的基地址不是 0）
        rm.default_map.set_base_addr(32'h0);

        // 告诉 Predictor 使用哪个 Adapter 和哪个 Map
        reg_predictor.map     = rm.default_map;
        reg_predictor.adapter = adapter;

        agt.mon.ap.connect(reg_predictor.bus_in);
        virt_sqr.agt_sqr = agt.sqr;

        if(cfg.enable_scb) begin
            agt.mon.ap.connect(scb.exp_fifo.analysis_export);
            slv_agt.mon.ap.connect(scb.act_fifo.analysis_export);
        end

        if(cfg.enable_cov) begin
            agt.mon.ap.connect(cov.analysis_export);

        // 关闭隐式预测，开启显式预测
        rm.default_map.set_auto_predict(0);
    endfunction
endclass

`endif // AXIL_REGISTER_ENV_SV