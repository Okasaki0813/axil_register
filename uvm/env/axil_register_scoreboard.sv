`ifndef AXIL_REGISTER_SCOREBOARD_SV
`define AXIL_REGISTER_SCOREBOARD_SV

`include "uvm_macros.svh"

class axil_register_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axil_register_scoreboard)

    int check_count;
    int error_count;

    axil_register_config cfg;

    uvm_tlm_analysis_fifo #(axil_register_transaction) mst_fifo; // uvm_tlm_analysis_fifo是一个带缓存功能的信箱
    uvm_tlm_analysis_fifo #(axil_register_transaction) slv_fifo;

    function new(string name = "axil_register_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mst_fifo = new("mst_fifo", this);
        slv_fifo = new("slv_fifo", this);
        
        if(!uvm_config_db#(axil_register_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("NOCFG", "Scoreboard cannot get configuration object from config_db!")
        end
    endfunction

    // 在run_phase中不断比对两个信箱中的数据
    virtual task run_phase(uvm_phase phase);
        axil_register_transaction mst_tr, slv_tr;
        forever begin
            mst_fifo.get(mst_tr); // get是这个变量内置的函数，作用是从信箱中获取数据
            slv_fifo.get(slv_tr);

            if (mst_tr.compare(slv_tr)) begin // compare函数返回的是bool值，1代表相同，0代表不同
                `uvm_info("SCB", "Match! DUT sent what scoreboard received.", UVM_HIGH)
            end else begin
                `uvm_error("SCB", "Mismatch! Package corrupted at the DUT!")
            end
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), 
                $sformatf("Scoreboard Statistics: Total Checks=%0d, Errors=%0d", 
                        check_count, error_count), 
                UVM_LOW)
    endfunction
endclass

`endif // AXIL_REGISTER_SCOREBOARD_SV