// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2018-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall // 重置编译器的状态。
          // 为什么之前的文件中定义的宏可能会影响到当前文件的编译？
          // 宏定义的常量是全局的
`timescale 1ns / 1ps
`default_nettype none // 要求所有信号都要先声明再使用，否则编译器会直接报错

/*
 * AXI4 lite register
 * 该模块用于在AXI-Lite的五个通道中灵活插入寄存器以切断组合逻辑路径
 * 为什么要用寄存器切断组合逻辑路径？若组合逻辑过长，信号可能无法在一个时钟周期内跑到终点，从而造成时序违例
 * 寄存器是如何切断组合逻辑路径的？将一条组合逻辑链拆分为两条
 */
module taxi_axil_register #
(
    // 0 to bypass, 1 for simple buffer
    // 0：Bypass，旁路，不打拍，直接透传
    // 打1拍就是延迟一个时钟周期
    // 透传就是信号不经过任何寄存器，直接从输入端到达输出端
    // 1：Simple buffer，简单缓冲
    // 为什么增加一个时钟周期的延迟有助于降低该路径的逻辑压力？延长组合逻辑链
    // AW channel register type
    parameter AW_REG_TYPE = 1, // 写地址通道寄存器类型
    // W channel register type
    parameter W_REG_TYPE = 1, // 写数据通道寄存器类型
    // B channel register type
    parameter B_REG_TYPE = 1, // 写响应通道寄存器类型
    // AR channel register type
    parameter AR_REG_TYPE = 1, // 读地址通道寄存器类型
    // R channel register type
    parameter R_REG_TYPE = 1 // 读数据通道寄存器类型
)
(
    input  wire logic    clk, // 全局时钟信号
    input  wire logic    rst, // 全局复位信号

    /*
     * AXI4-Lite slave interface
     * 这是面向主机的从机接口，其任务是接收来自Master的原始请求
     * 原始请求是指由Master发出的、未经任何处理（例如打拍、协议转换、位宽调整等）的信号
     * 非原始请求就是指经过寄存器模块处理后的信号，它的时序更优
     */
    taxi_axil_if.wr_slv  s_axil_wr, // 写通道从机口
    taxi_axil_if.rd_slv  s_axil_rd, // 读通道从机口

    /*
     * AXI4-Lite master interface
     * 这是面向从机的主机接口，任务是将打拍后的请求转发给真正的Slave，例如内存或外设（那么之前提到的slave是什么呢？）
     */
    taxi_axil_if.wr_mst  m_axil_wr, // 写通道主机口
    taxi_axil_if.rd_mst  m_axil_rd // 读通道主机口
);

/*
 * 实例化写通道处理子模块
 * 该模块负责AW、W、B三个通道的寄存逻辑
 */
taxi_axil_register_wr #(
    .AW_REG_TYPE(AW_REG_TYPE),
    .W_REG_TYPE(W_REG_TYPE),
    .B_REG_TYPE(B_REG_TYPE)
)
axil_register_wr_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Lite slave interface
     */
    .s_axil_wr(s_axil_wr), // 连接从机侧写接口

    /*
     * AXI4-Lite master interface
     */
    .m_axil_wr(m_axil_wr) // 连接主机侧写接口
);

/*
 * 实例化读通道处理子模块
 * 该模块负责AR、R两个通道的寄存逻辑
 */
taxi_axil_register_rd #(
    .AR_REG_TYPE(AR_REG_TYPE),
    .R_REG_TYPE(R_REG_TYPE)
)
axil_register_rd_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Lite slave interface
     */
    .s_axil_rd(s_axil_rd), // 连接从机侧读接口

    /*
     * AXI4-Lite master interface
     */
    .m_axil_rd(m_axil_rd) // 连接主机侧读接口
);

endmodule

`resetall
