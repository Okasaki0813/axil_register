// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2018-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4 lite register (write)
 * 该模块专门处理AXI-Lite的AW、W、B三个通道
 * 每个通道可独立配置为三种工作模式：旁路、简单缓冲、滑行缓冲
 * 旁路：直接连线，无延迟
 * 简单缓冲：单级寄存器，有气泡周期
 * 滑行缓冲：两级寄存器，无气泡周期
 */
module taxi_axil_register_wr #
(
    // AW channel register type
    parameter AW_REG_TYPE = 1, // unsigned int
    // W channel register type
    parameter W_REG_TYPE = 1,
    // B channel register type
    parameter B_REG_TYPE = 1
)
(
    input  wire logic    clk,
    input  wire logic    rst,

    /*
     * AXI4-Lite slave interface
     * 作用：连接上游设备（Master），接收写操作请求
     */
    taxi_axil_if.wr_slv  s_axil_wr, // 写通道从机口

    /*
     * AXI4-Lite master interface
     * 作用：连接下游设备（Slave），发送处理后的写操作请求
     */
    taxi_axil_if.wr_mst  m_axil_wr // 写通道主机口
);

// extract parameters 提取参数
// localparam是局部参数，这种参数的作用范围是仅限于该模块内部
// parameter可由顶层模块在实例化时修改，而localparam无法由外部修改
localparam DATA_W = s_axil_wr.DATA_W;
localparam ADDR_W = s_axil_wr.ADDR_W;
localparam STRB_W = s_axil_wr.STRB_W;

// 判断是否启用用户自定义信号
// 用户自定义信号是用来干嘛的？
// 为什么要主机和从机都启用用户自定义信号才生效呢？只有当Master和Slave都支持时才需要连接
localparam logic AWUSER_EN = s_axil_wr.AWUSER_EN && m_axil_wr.AWUSER_EN;
localparam AWUSER_W = s_axil_wr.AWUSER_W;
localparam logic WUSER_EN = s_axil_wr.WUSER_EN && m_axil_wr.WUSER_EN;
localparam WUSER_W = s_axil_wr.WUSER_W;
localparam logic BUSER_EN = s_axil_wr.BUSER_EN && m_axil_wr.BUSER_EN;
localparam BUSER_W = s_axil_wr.BUSER_W;

// 检查数据宽度和写掩码是否匹配
if (m_axil_wr.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)"); // 这里的%m是当前模块的层次化路径名？

if (m_axil_wr.STRB_W != STRB_W)
    $fatal(0, "Error: Interface STRB_W parameter mismatch (instance %m)");

// AW channel
// 写地址通道处理逻辑

if (AW_REG_TYPE > 1) begin
    // skid buffer 滑行缓冲区模式
    // no bubble cycles 无气泡周期
    /* 工作原理
     * 使用两级寄存器：主寄存器m_*和临时寄存器temp_*
     * 当主寄存器满且从设备无法接收时，数据暂存到临时寄存器中
     * 使用临时寄存器可以避免丢失数据，从而保持连续传输
     */

    // datapath registers 数据通路寄存器
    logic                 s_axil_awready_reg = 1'b0; // 表示该模块是否准备好作为从设备接收来自主设备发送的地址

    // 主寄存器组：设备要发送给下游的数据
    logic [ADDR_W-1:0]    m_axil_awaddr_reg   = '0;
    logic [2:0]           m_axil_awprot_reg   = '0;
    logic [AWUSER_W-1:0]  m_axil_awuser_reg   = '0;
    logic                 m_axil_awvalid_reg  = 1'b0;
    logic                 m_axil_awvalid_next;

    // 临时寄存器组：当主寄存器满且下游忙时，临时存储数据
    logic [ADDR_W-1:0]    temp_m_axil_awaddr_reg   = '0;
    logic [2:0]           temp_m_axil_awprot_reg   = '0;
    logic [AWUSER_W-1:0]  temp_m_axil_awuser_reg   = '0;
    logic                 temp_m_axil_awvalid_reg  = 1'b0;
    logic                 temp_m_axil_awvalid_next;

    // datapath control 数据通路控制信号
    logic store_axil_aw_input_to_output; // 输入数据存储到主寄存器
    logic store_axil_aw_input_to_temp; // 输入数据存储到临时寄存器
    logic store_axil_aw_temp_to_output; // 临时寄存器数据移动到主寄存器

    assign s_axil_wr.awready  = s_axil_awready_reg;

    assign m_axil_wr.awaddr   = m_axil_awaddr_reg;
    assign m_axil_wr.awprot   = m_axil_awprot_reg;
    assign m_axil_wr.awuser   = AWUSER_EN ? m_axil_awuser_reg : '0;
    assign m_axil_wr.awvalid  = m_axil_awvalid_reg;

    // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
    /* 提前计算下一个周期的ready信号
     * 条件：下游准备好 || （临时寄存器空 && （主寄存器空 || 没有新输入）
     */
    wire s_axil_awready_early = m_axil_wr.awready || 
                                (!temp_m_axil_awvalid_reg && 
                                (!m_axil_awvalid_reg || !s_axil_wr.awvalid));

    // 控制数据流向的状态机
    // 作用：根据当前状态和接口信号，决定数据的流向（直通 or 存临时 or 从临时读取）
    // 在这个组合逻辑块中，更改的都是valid信号的值，为什么会决定数据流向呢？
    always_comb begin
        // transfer sink ready state to source
        m_axil_awvalid_next = m_axil_awvalid_reg;
        temp_m_axil_awvalid_next = temp_m_axil_awvalid_reg;

        store_axil_aw_input_to_output = 1'b0;
        store_axil_aw_input_to_temp = 1'b0;
        store_axil_aw_temp_to_output = 1'b0;

        if (s_axil_awready_reg) begin
            // input is ready
            // 情况1：该设备已作为从设备准备好接收数据
            if (m_axil_wr.awready || !m_axil_awvalid_reg) begin
                // output is ready or currently not valid, transfer data to output
                // 子情况1a：下游准备好接收 or 主寄存器为空
                // 直接将输入数据存储到主寄存器中（这个操作体现在哪行代码中？）
                m_axil_awvalid_next = s_axil_wr.awvalid; // 激活主寄存器的有效信号
                store_axil_aw_input_to_output = 1'b1;
            end else begin
                // output is not ready, store input in temp
                // 子情况1b：下游忙且主寄存器满
                // 将输入数据存储到临时寄存器
                temp_m_axil_awvalid_next = s_axil_wr.awvalid; // 激活临时寄存器的有效信号
                store_axil_aw_input_to_temp = 1'b1;
            end
        end else if (m_axil_wr.awready) begin
            // input is not ready, but output is ready
            // 情况2：该设备尚未准备好接收信号，但下游从设备准备好了
            // 将临时寄存器中的数据移到主寄存器中
            m_axil_awvalid_next = temp_m_axil_awvalid_reg;
            temp_m_axil_awvalid_next = 1'b0;
            store_axil_aw_temp_to_output = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        // 更新控制信号寄存器
        s_axil_awready_reg <= s_axil_awready_early; // 这个控制信号是之前已经计算好的下一个周期中寄存器的有效信号吗？为什么它的后缀是early，而不是和后面一样是next？
        m_axil_awvalid_reg <= m_axil_awvalid_next;
        temp_m_axil_awvalid_reg <= temp_m_axil_awvalid_next;

        // datapath
        // 根据控制信号更新数据寄存器
        if (store_axil_aw_input_to_output) begin
            // 情况1：输入数据存储到主寄存器
            m_axil_awaddr_reg <= s_axil_wr.awaddr;
            m_axil_awprot_reg <= s_axil_wr.awprot;
            m_axil_awuser_reg <= s_axil_wr.awuser;
        end else if (store_axil_aw_temp_to_output) begin
            // 情况2：临时寄存器的数据移到主寄存器中
            m_axil_awaddr_reg <= temp_m_axil_awaddr_reg;
            m_axil_awprot_reg <= temp_m_axil_awprot_reg;
            m_axil_awuser_reg <= temp_m_axil_awuser_reg;
        end

        // 更新临时寄存器
        if (store_axil_aw_input_to_temp) begin
            // 将输入数据存储到临时寄存器中
            temp_m_axil_awaddr_reg <= s_axil_wr.awaddr;
            temp_m_axil_awprot_reg <= s_axil_wr.awprot;
            temp_m_axil_awuser_reg <= s_axil_wr.awuser;
        end

        if (rst) begin
            s_axil_awready_reg <= 1'b0;
            m_axil_awvalid_reg <= 1'b0;
            temp_m_axil_awvalid_reg <= 1'b0;
        end
    end

end else if (AW_REG_TYPE == 1) begin
    // simple register, inserts bubble cycles
    // 简单缓冲模式
    // 单级寄存器、有气泡周期

    // datapath registers
    logic                 s_axil_awready_reg = 1'b0;

    logic [ADDR_W-1:0]    m_axil_awaddr_reg   = '0;
    logic [2:0]           m_axil_awprot_reg   = '0;
    logic [AWUSER_W-1:0]  m_axil_awuser_reg   = '0;
    logic                 m_axil_awvalid_reg  = 1'b0;
    logic                 m_axil_awvalid_next;

    // datapath control
    logic store_axil_aw_input_to_output;

    assign s_axil_wr.awready  = s_axil_awready_reg;

    assign m_axil_wr.awaddr   = m_axil_awaddr_reg;
    assign m_axil_wr.awprot   = m_axil_awprot_reg;
    assign m_axil_wr.awuser   = AWUSER_EN ? m_axil_awuser_reg : '0;
    assign m_axil_wr.awvalid  = m_axil_awvalid_reg;

    // 作为从机，只有当下一个周期没有数据要发送时，才准备好接收新的地址
    wire s_axil_awready_early = !m_axil_awvalid_next;

    always_comb begin
        // transfer sink ready state to source
        m_axil_awvalid_next = m_axil_awvalid_reg;

        store_axil_aw_input_to_output = 1'b0;

        if (s_axil_awready_reg) begin
            m_axil_awvalid_next = s_axil_wr.awvalid;
            store_axil_aw_input_to_output = 1'b1;
        end else if (m_axil_wr.awready) begin
            m_axil_awvalid_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        s_axil_awready_reg <= s_axil_awready_early;
        m_axil_awvalid_reg <= m_axil_awvalid_next;

        // datapath
        if (store_axil_aw_input_to_output) begin
            m_axil_awaddr_reg <= s_axil_wr.awaddr;
            m_axil_awprot_reg <= s_axil_wr.awprot;
            m_axil_awuser_reg <= s_axil_wr.awuser;
        end

        if (rst) begin
            s_axil_awready_reg <= 1'b0;
            m_axil_awvalid_reg <= 1'b0;
        end
    end

end else begin

    // bypass AW channel
    assign m_axil_wr.awaddr = s_axil_wr.awaddr;
    assign m_axil_wr.awprot = s_axil_wr.awprot;
    assign m_axil_wr.awuser = AWUSER_EN ? s_axil_wr.awuser : '0;
    assign m_axil_wr.awvalid = s_axil_wr.awvalid;
    assign s_axil_wr.awready = m_axil_wr.awready;

end

// W channel
// 写数据通道处理逻辑

if (W_REG_TYPE > 1) begin
    // skid buffer, no bubble cycles

    // datapath registers
    logic                s_axil_wready_reg = 1'b0;

    logic [DATA_W-1:0]   m_axil_wdata_reg  = '0;
    logic [STRB_W-1:0]   m_axil_wstrb_reg  = '0;
    logic [WUSER_W-1:0]  m_axil_wuser_reg  = '0;
    logic                m_axil_wvalid_reg = 1'b0, m_axil_wvalid_next;

    logic [DATA_W-1:0]   temp_m_axil_wdata_reg  = '0;
    logic [STRB_W-1:0]   temp_m_axil_wstrb_reg  = '0;
    logic [WUSER_W-1:0]  temp_m_axil_wuser_reg  = '0;
    logic                temp_m_axil_wvalid_reg = 1'b0, temp_m_axil_wvalid_next;

    // datapath control
    logic store_axil_w_input_to_output;
    logic store_axil_w_input_to_temp;
    logic store_axil_w_temp_to_output;

    assign s_axil_wr.wready = s_axil_wready_reg;

    assign m_axil_wr.wdata  = m_axil_wdata_reg;
    assign m_axil_wr.wstrb  = m_axil_wstrb_reg;
    assign m_axil_wr.wuser  = WUSER_EN ? m_axil_wuser_reg : '0;
    assign m_axil_wr.wvalid = m_axil_wvalid_reg;

    // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
    wire s_axil_wready_early = m_axil_wr.wready || (!temp_m_axil_wvalid_reg && (!m_axil_wvalid_reg || !s_axil_wr.wvalid));

    always_comb begin
        // transfer sink ready state to source
        m_axil_wvalid_next = m_axil_wvalid_reg;
        temp_m_axil_wvalid_next = temp_m_axil_wvalid_reg;

        store_axil_w_input_to_output = 1'b0;
        store_axil_w_input_to_temp = 1'b0;
        store_axil_w_temp_to_output = 1'b0;

        if (s_axil_wready_reg) begin
            // input is ready
            if (m_axil_wr.wready || !m_axil_wvalid_reg) begin
                // output is ready or currently not valid, transfer data to output
                m_axil_wvalid_next = s_axil_wr.wvalid;
                store_axil_w_input_to_output = 1'b1;
            end else begin
                // output is not ready, store input in temp
                temp_m_axil_wvalid_next = s_axil_wr.wvalid;
                store_axil_w_input_to_temp = 1'b1;
            end
        end else if (m_axil_wr.wready) begin
            // input is not ready, but output is ready
            m_axil_wvalid_next = temp_m_axil_wvalid_reg;
            temp_m_axil_wvalid_next = 1'b0;
            store_axil_w_temp_to_output = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        s_axil_wready_reg <= s_axil_wready_early;
        m_axil_wvalid_reg <= m_axil_wvalid_next;
        temp_m_axil_wvalid_reg <= temp_m_axil_wvalid_next;

        // datapath
        if (store_axil_w_input_to_output) begin
            m_axil_wdata_reg <= s_axil_wr.wdata;
            m_axil_wstrb_reg <= s_axil_wr.wstrb;
            m_axil_wuser_reg <= s_axil_wr.wuser;
        end else if (store_axil_w_temp_to_output) begin
            m_axil_wdata_reg <= temp_m_axil_wdata_reg;
            m_axil_wstrb_reg <= temp_m_axil_wstrb_reg;
            m_axil_wuser_reg <= temp_m_axil_wuser_reg;
        end

        if (store_axil_w_input_to_temp) begin
            temp_m_axil_wdata_reg <= s_axil_wr.wdata;
            temp_m_axil_wstrb_reg <= s_axil_wr.wstrb;
            temp_m_axil_wuser_reg <= s_axil_wr.wuser;
        end

        if (rst) begin
            s_axil_wready_reg <= 1'b0;
            m_axil_wvalid_reg <= 1'b0;
            temp_m_axil_wvalid_reg <= 1'b0;
        end
    end

end else if (W_REG_TYPE == 1) begin
    // simple register, inserts bubble cycles

    // datapath registers
    logic                s_axil_wready_reg = 1'b0;

    logic [DATA_W-1:0]   m_axil_wdata_reg  = '0;
    logic [STRB_W-1:0]   m_axil_wstrb_reg  = '0;
    logic [WUSER_W-1:0]  m_axil_wuser_reg  = '0;
    logic                m_axil_wvalid_reg = 1'b0, m_axil_wvalid_next;

    // datapath control
    logic store_axil_w_input_to_output;

    assign s_axil_wr.wready = s_axil_wready_reg;

    assign m_axil_wr.wdata  = m_axil_wdata_reg;
    assign m_axil_wr.wstrb  = m_axil_wstrb_reg;
    assign m_axil_wr.wuser  = WUSER_EN ? m_axil_wuser_reg : '0;
    assign m_axil_wr.wvalid = m_axil_wvalid_reg;

    // enable ready input next cycle if output buffer will be empty
    wire s_axil_wready_early = !m_axil_wvalid_next;

    always_comb begin
        // transfer sink ready state to source
        m_axil_wvalid_next = m_axil_wvalid_reg;

        store_axil_w_input_to_output = 1'b0;

        if (s_axil_wready_reg) begin
            m_axil_wvalid_next = s_axil_wr.wvalid;
            store_axil_w_input_to_output = 1'b1;
        end else if (m_axil_wr.wready) begin
            m_axil_wvalid_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        s_axil_wready_reg <= s_axil_wready_early;
        m_axil_wvalid_reg <= m_axil_wvalid_next;

        // datapath
        if (store_axil_w_input_to_output) begin
            m_axil_wdata_reg <= s_axil_wr.wdata;
            m_axil_wstrb_reg <= s_axil_wr.wstrb;
            m_axil_wuser_reg <= s_axil_wr.wuser;
        end

        if (rst) begin
            s_axil_wready_reg <= 1'b0;
            m_axil_wvalid_reg <= 1'b0;
        end
    end

end else begin

    // bypass W channel
    assign m_axil_wr.wdata = s_axil_wr.wdata;
    assign m_axil_wr.wstrb = s_axil_wr.wstrb;
    assign m_axil_wr.wuser = WUSER_EN ? s_axil_wr.wuser : '0;
    assign m_axil_wr.wvalid = s_axil_wr.wvalid;
    assign s_axil_wr.wready = m_axil_wr.wready;

end

// B channel
// 写响应通道处理逻辑

if (B_REG_TYPE > 1) begin
    // skid buffer, no bubble cycles

    // datapath registers
    logic                m_axil_bready_reg = 1'b0;

    logic [1:0]          s_axil_bresp_reg  = 2'b0;
    logic [BUSER_W-1:0]  s_axil_buser_reg  = '0;
    logic                s_axil_bvalid_reg = 1'b0, s_axil_bvalid_next;

    logic [1:0]          temp_s_axil_bresp_reg  = 2'b0;
    logic [BUSER_W-1:0]  temp_s_axil_buser_reg  = '0;
    logic                temp_s_axil_bvalid_reg = 1'b0, temp_s_axil_bvalid_next;

    // datapath control
    logic store_axil_b_input_to_output;
    logic store_axil_b_input_to_temp;
    logic store_axil_b_temp_to_output;

    assign m_axil_wr.bready = m_axil_bready_reg;

    assign s_axil_wr.bresp  = s_axil_bresp_reg;
    assign s_axil_wr.buser  = BUSER_EN ? s_axil_buser_reg : '0;
    assign s_axil_wr.bvalid = s_axil_bvalid_reg;

    // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
    wire m_axil_bready_early = s_axil_wr.bready || (!temp_s_axil_bvalid_reg && (!s_axil_bvalid_reg || !m_axil_wr.bvalid));

    always_comb begin
        // transfer sink ready state to source
        s_axil_bvalid_next = s_axil_bvalid_reg;
        temp_s_axil_bvalid_next = temp_s_axil_bvalid_reg;

        store_axil_b_input_to_output = 1'b0;
        store_axil_b_input_to_temp = 1'b0;
        store_axil_b_temp_to_output = 1'b0;

        if (m_axil_bready_reg) begin
            // input is ready
            if (s_axil_wr.bready || !s_axil_bvalid_reg) begin
                // output is ready or currently not valid, transfer data to output
                s_axil_bvalid_next = m_axil_wr.bvalid;
                store_axil_b_input_to_output = 1'b1;
            end else begin
                // output is not ready, store input in temp
                temp_s_axil_bvalid_next = m_axil_wr.bvalid;
                store_axil_b_input_to_temp = 1'b1;
            end
        end else if (s_axil_wr.bready) begin
            // input is not ready, but output is ready
            s_axil_bvalid_next = temp_s_axil_bvalid_reg;
            temp_s_axil_bvalid_next = 1'b0;
            store_axil_b_temp_to_output = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        m_axil_bready_reg <= m_axil_bready_early;
        s_axil_bvalid_reg <= s_axil_bvalid_next;
        temp_s_axil_bvalid_reg <= temp_s_axil_bvalid_next;

        // datapath
        if (store_axil_b_input_to_output) begin
            s_axil_bresp_reg <= m_axil_wr.bresp;
            s_axil_buser_reg <= m_axil_wr.buser;
        end else if (store_axil_b_temp_to_output) begin
            s_axil_bresp_reg <= temp_s_axil_bresp_reg;
            s_axil_buser_reg <= temp_s_axil_buser_reg;
        end

        if (store_axil_b_input_to_temp) begin
            temp_s_axil_bresp_reg <= m_axil_wr.bresp;
            temp_s_axil_buser_reg <= m_axil_wr.buser;
        end

        if (rst) begin
            m_axil_bready_reg <= 1'b0;
            s_axil_bvalid_reg <= 1'b0;
            temp_s_axil_bvalid_reg <= 1'b0;
        end
    end

end else if (B_REG_TYPE == 1) begin
    // simple register, inserts bubble cycles

    // datapath registers
    logic                m_axil_bready_reg = 1'b0;

    logic [1:0]          s_axil_bresp_reg  = 2'b0;
    logic [BUSER_W-1:0]  s_axil_buser_reg  = '0;
    logic                s_axil_bvalid_reg = 1'b0, s_axil_bvalid_next;

    // datapath control
    logic store_axil_b_input_to_output;

    assign m_axil_wr.bready = m_axil_bready_reg;

    assign s_axil_wr.bresp  = s_axil_bresp_reg;
    assign s_axil_wr.buser  = BUSER_EN ? s_axil_buser_reg : '0;
    assign s_axil_wr.bvalid = s_axil_bvalid_reg;

    // enable ready input next cycle if output buffer will be empty
    wire m_axil_bready_early = !s_axil_bvalid_next;

    always_comb begin
        // transfer sink ready state to source
        s_axil_bvalid_next = s_axil_bvalid_reg;

        store_axil_b_input_to_output = 1'b0;

        if (m_axil_bready_reg) begin
            s_axil_bvalid_next = m_axil_wr.bvalid;
            store_axil_b_input_to_output = 1'b1;
        end else if (s_axil_wr.bready) begin
            s_axil_bvalid_next = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        m_axil_bready_reg <= m_axil_bready_early;
        s_axil_bvalid_reg <= s_axil_bvalid_next;

        // datapath
        if (store_axil_b_input_to_output) begin
            s_axil_bresp_reg <= m_axil_wr.bresp;
            s_axil_buser_reg <= m_axil_wr.buser;
        end

        if (rst) begin
            m_axil_bready_reg <= 1'b0;
            s_axil_bvalid_reg <= 1'b0;
        end
    end

end else begin

    // bypass B channel
    assign s_axil_wr.bresp = m_axil_wr.bresp;
    assign s_axil_wr.buser = BUSER_EN ? m_axil_wr.buser : '0;
    assign s_axil_wr.bvalid = m_axil_wr.bvalid;
    assign m_axil_wr.bready = s_axil_wr.bready;

end

endmodule

`resetall
