`ifndef AXIL_REGISTER_TOP_SV
`define AXIL_REGISTER_TOP_SV

`include "uvm_macros.svh"

module top;
    logic clk;
    logic rst;

    // 生成时钟信号，频率为100MHz
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 生成复位信号
    // AXI4-Lite 中复位是低有效 (active low)
    // rst = 1'b0: 复位生效（系统处于复位状态）
    // rst = 1'b1: 复位释放（系统正常工作）
    initial begin
        rst = 1'b0;      // 初始时施加复位（低有效）
        #50 rst = 1'b1;  // 等待 50ns 后释放复位，给足充分的复位时间地址译码与非法地址处理: 不同地址映射正确性、保留/越界地址的响应行为（DECERR/SLVERR）。
    end

    // 为避免 DUT 内部将 m_axil_* 和 s_axil_* 连接到同一个接口实例
    //（这会导致模块内部对同一信号的双重驱动，例如 m_axil_wr.bready 与
    // 测试平台驱动的 bready 同时驱动同一 net），这里使用两个接口实例：
    // - `master_if`：连接到 DUT 的主机侧端口（下游 slave 的一侧）
    // - `slave_if` : 连接到 DUT 的从机侧端口（上游 master 的一侧）
    // Testbench 的 Master Agent 应使用 `slave_if`，Slave Agent 使用 `master_if`。
    taxi_axil_if #(
        .DATA_W(32),
        .ADDR_W(32)
    ) master_if(
        .clk(clk),
        .rst(rst)
    );

    taxi_axil_if #(
        .DATA_W(32),
        .ADDR_W(32)
    ) slave_if(
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
        // 连接：DUT 的从机口接到 `slave_if`，DUT 的主机口接到 `master_if`
        .s_axil_wr(slave_if.wr_slv),
        .s_axil_rd(slave_if.rd_slv),
        .m_axil_wr(master_if.wr_mst),
        .m_axil_rd(master_if.rd_mst)
    );

    initial begin
        // 为 Test 层设置接口（test 层需要 vif 来获取配置）
        // 将不同的接口实例分配给不同的 agent：
        // - test 和 Master Agent 使用 `slave_if`（它连接到 DUT 的从机口），
        //   因为 Master Agent 要驱动进入 DUT 的请求（s_axil_*）。
        // - Slave Agent 使用 `master_if`（它连接到 DUT 的主机口），
        //   因为 Slave Agent 模拟下游从设备并驱动 m_axil_* 信号。
        uvm_config_db#(virtual taxi_axil_if)::set(null, "uvm_test_top*", "vif", slave_if);

        uvm_config_db#(virtual taxi_axil_if)::set(null, "uvm_test_top.env.agt*", "vif", slave_if);

        uvm_config_db#(virtual taxi_axil_if)::set(null, "uvm_test_top.env.slv_agt*", "vif", master_if);
        // null：该配置的起始路径
        // "uvm_test_top.env.slv_agt*"：目标组件的相对/绝对路径
        // vif：存放在数据库中的key
        // dut_if：需要传递的实际对象句柄

        run_test();
    end
endmodule

`endif // AXIL_REGISTER_TOP_SV