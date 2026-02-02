`ifndef AXIL_REGISTER_SLAVE_MONITOR_SV
`define AXIL_REGISTER_SLAVE_MONITOR_SV

`include "uvm_macros.svh"

class axil_register_slave_monitor extends axil_register_base_monitor;
    `uvm_component_utils(axil_register_slave_monitor)

    function new(string name = "axil_register_slave_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    extern virtual task collect_write_data();
    extern virtual task collect_read_data();
endclass

task axil_register_slave_monitor::collect_write_data();
    axil_register_transaction tr;
    bit aw_done, w_done;

    forever begin
        aw_done = 1'b0;
        w_done  = 1'b0;

        // 使用临时变量储存对应数据，防止在等待过程中被覆盖
        logic [ADDR_W-1:0]    temp_awaddr;
        logic [2:0]           temp_awprot;

        logic [DATA_W-1:0]    temp_wdata;
        logic [STRB_W-1:0]    temp_wstrb;

        fork
            begin
                wait(vif.awvalid === 1'b1 && vif.awready === 1'b1);
                temp_awaddr = vif.awaddr;
                temp_awprot = vif.awprot;
                aw_done = 1'b1;
            end

            begin
                wait(vif.wvalid === 1'b1 && vif.wready === 1'b1);
                temp_wdata = vif.wdata;
                temp_wstrb = vif.wstrb;
                w_done = 1'b1;
            end
        join_none

        wait(aw_done && w_done);
        disable fork;

        tr = axil_register_transaction::type_id::create("tr");
        tr.operation = axil_register_transaction::WRITE;

        tr.addr = temp_awaddr;
        tr.prot = temp_awprot;

        tr.data = temp_wdata;
        tr.strb = temp_wstrb;

        wait(vif.bvalid === 1'b1 && vif.bready === 1'b1);
        tr.resp = vif.bresp;
        
        @(posedge vif.clk);
        ap.write(tr);
        `uvm_info(get_type_name(), $sformatf("Collected a WRITE transaction, addr=0x%0h, data=0x%0h", tr.addr, tr.data), UVM_HIGH)
    end
endtask

task axil_register_slave_monitor::collect_read_data();
    axil_register_transaction tr;

    forever begin
        tr = axil_register_transaction::type_id::create("tr");
        tr.operation = axil_register_transaction::READ;

        wait(vif.arvalid === 1'b1 && vif.arready === 1'b1);
        tr.addr = vif.araddr;
        tr.prot = vif.arprot;
        tr.user = vif.aruser;

        wait(vif.rvalid === 1'b1 && vif.rready === 1'b1);
        tr.data = vif.rdata;
        tr.resp = vif.rresp;

        @(posedge vif.clk);
        ap.write(tr);
    end
endtask
`endif // AXIL_REGISTER_SLAVE_MONITOR_SV