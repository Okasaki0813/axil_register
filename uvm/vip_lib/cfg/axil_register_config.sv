`ifndef AXIL_REGISTER_CONFIG_SV
`define AXIL_REGISTER_CONFIG_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class axil_register_config extends uvm_object;

    bit has_master = 1;                     // 是否包含master agent
    bit has_slave  = 1;                     // 是否包含slave agent

    bit enable_cov = 1;                     // 是否启用覆盖率收集
    bit enable_scb = 1;                     // 是否启用scoreboard比对

    uvm_active_passive_enum master_active = UVM_ACTIVE;  // master agent模式
    uvm_active_passive_enum slave_active  = UVM_ACTIVE;  // slave agent模式

    bit [31:0]  addr_start = 32'h0000_0000;
    bit [31:0]  addr_end   = 32'hFFFF_FFFF;

    int addr_width = 32;
    int data_width = 32;
    int strb_width = data_width / 8;

    virtual taxi_axil_if mst_vif;
    virtual taxi_axil_if slv_vif;

    // // ========== 测试控制 ==========
    // int test_timeout = 100000;            // 测试超时时间（时钟周期）
    // bit error_injection_enable = 0;       // 是否启用错误注入
    // int error_rate = 5;                   // 错误注入率（百分比）
    
    // // ========== 协议参数 ==========
    // int min_response_delay = 0;           // 最小响应延迟
    // int max_response_delay = 5;           // 最大响应延迟

    `uvm_object_utils_begin(axil_register_config)
        `uvm_field_int(has_master, UVM_ALL_ON)
        `uvm_field_int(has_slave, UVM_ALL_ON)

        `uvm_field_int(enable_scb, UVM_ALL_ON)
        `uvm_field_int(enable_cov, UVM_ALL_ON)

        `uvm_field_int(master_active, UVM_ALL_ON)
        `uvm_field_int(slave_active, UVM_ALL_ON)

        `uvm_field_int(addr_start, UVM_ALL_ON)
        `uvm_field_int(addr_end, UVM_ALL_ON)

        `uvm_field_int(addr_width, UVM_ALL_ON)
        `uvm_field_int(data_width, UVM_ALL_ON)
        `uvm_field_int(strb_width, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axil_register_config");
        super.new(name);
    endfunction

    // 检查地址是否在有效范围内
    function bit is_address_valid(bit [31:0] addr);
        return (addr >= addr_start && addr <= addr_end);
    endfunction
endclass

`endif // AXIL_REGISTER_CONFIG_SV