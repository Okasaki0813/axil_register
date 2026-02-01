`include "uvm_macros.svh"

// `include "taxi_axil_if.sv"
// `include "axil_register_transaction.sv"
// `include "axil_register_base_test.sv"

module top;
    logic clk;
    logic rst;

    // 生成时钟信号，频率为100MHz
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 生成复位信号
    initial begin
        rst = 1'b1;
        #20 rst = 1'b0;
    end

    taxi_axil_if #(
        .DATA_W(32),
        .ADDR_W(32)
    ) dut_if(
        .clk(clk),
        .rst(rst)
    );

    taxi_axil_register #(
        .AW_REG_TYPE(1),
        .W_REG_TYPE (1),
        .B_REG_TYPE (1),
        .AR_REG_TYPE(1),
        .R_REG_TYPE (1)
    ) dut (
        .clk(clk),
        .rst(rst),
        .s_axil_wr(dut_if.wr_slv),
        .s_axil_rd(dut_if.rd_slv),
        .m_axil_wr(dut_if.wr_mst),
        .m_axil_rd(dut_if.rd_mst)
    );

//     initial begin
//         uvm_config_db#(virtual taxi_axil_if)::set(null, "uvm_test_top.*", "vif", dut_if); // 这四个参数分别是什么意思？
//                                                                                           // null是上下文路径
//                                                                                           // uvm_test_top:*是目标路径
//                                                                                           // vif是key
//                                                                                           // dut_if是value
//         // 在 top.sv 中增加一条 config_db 设置
// uvm_config_db#(virtual taxi_axil_if)::set(null, "uvm_test_top.env.slv_agt*", "vif", dut_if);
//         run_test("axil_register_base_test");
//     end

    initial begin
        // 为 Master Agent (agt) 设置接口，它负责驱动 s_axil (从机口)
        uvm_config_db#(virtual taxi_axil_if)::set(null, "uvm_test_top.env.agt*", "vif", dut_if);
        
        // 为 Slave Agent (slv_agt) 设置接口，它负责驱动 m_axil (主机口)
        // 这一步非常关键！Slave Agent 的 Driver 必须连接到 Master 侧
        uvm_config_db#(virtual taxi_axil_if)::set(null, "uvm_test_top.env.slv_agt*", "vif", dut_if);
        // null：该配置的起始路径
        // "uvm_test_top.env.slv_agt*"：目标组件的相对/绝对路径
        // vif：存放在数据库中的key
        // dut_if：需要传递的实际对象句柄

        run_test();
    end
endmodule