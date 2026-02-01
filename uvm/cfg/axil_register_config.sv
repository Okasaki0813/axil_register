`ifndef AXIL_REGISTER_CONFIG_SV
`define AXIL_REGISTER_CONFIG_SV

class axil_register_config extends uvm_object;

    bit enable_cov = 1; // 是否启用覆盖率收集
    bit enable_scb = 1; // 是否启用scoreboard比对

    // 设置地址边界及数据位宽
    bit [31:0]  addr_start = 32'h0000_0000;
    bit [31:0]  addr_end   = 32'hFFFF_FFFF;
    int         data_width = 32;

    virtual taxi_axil_if vif;

    `uvm_object_utils_begin(axil_register_config)
        `uvm_field_int(enable_cov, UVM_ALL_ON)
        `uvm_field_int(enable_scb, UVM_ALL_ON)
        `uvm_field_int(addr_start, UVM_ALL_ON)
        `uvm_field_int(addr_end,   UVM_ALL_ON)
        `uvm_field_int(data_width, UVM_ALL_ON)
    `uvm_object_utils_end

    function new (string name = "axil_register_config");
        super.new(name);
    endfunction
endclass

`endif // AXIL_REGISTER_CONFIG_SV