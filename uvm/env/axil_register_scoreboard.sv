`ifndef AXIL_REGISTER_SCOREBOARD_SV
`define AXIL_REGISTER_SCOREBOARD_SV

`include "uvm_macros.svh"

class axil_register_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axil_register_scoreboard)

    int check_count;
    int error_count;

    axil_register_config cfg;

    uvm_tlm_analysis_fifo #(axil_register_transaction) exp_fifo; // uvm_tlm_analysis_fifo是一个带缓存功能的信箱
                                                                 // #(axil_register_transaction)是指信箱需要接受的变量类型
    uvm_tlm_analysis_fifo #(axil_register_transaction) act_fifo;

    function new(string name = "axil_register_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        exp_fifo = new("exp_fifo", this);
        act_fifo = new("act_fifo", this);
        
        if(!uvm_config_db#(axil_register_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("NOCFG", "Scoreboard cannot get configuration object from config_db!")
        end
    endfunction

    // 在run_phase中不断比对两个信箱中的数据
    virtual task run_phase(uvm_phase phase);
        axil_register_transaction exp_tr, act_tr;
        forever begin
            exp_fifo.get(exp_tr); // get是这个变量内置的函数，作用是从信箱中获取数据
            act_fifo.get(act_tr);

            if (exp_tr.compare(act_tr)) begin // compare函数返回的是bool值，1代表相同，0代表不同
                `uvm_info("SCB", "Match! DUT sent what scoreboard received.", UVM_HIGH)
            end else begin
                `uvm_error("SCB", "Mismatch! Package corrupted at the DUT!")
            end
        end
    endtask
endclass

`endif // AXIL_REGISTER_SCOREBOARD_SV