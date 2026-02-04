`ifndef AXIL_REGISTER_COVERAGE_SV
`define AXIL_REGISTER_COVERAGE_SV

class axil_register_coverage extends uvm_subscriber #(axil_register_transaction);
    `uvm_component_utils(axil_register_coverage)

    axil_register_transaction m_item;
    
    covergroup axil_reg_cg; // 覆盖组是用来干嘛的？为什么一个覆盖组下面又分了好几个小组？
        cp_operation: coverpoint m_item.operation { // m_item是什么东西？
            bins op_read  = {axil_register_transaction::READ};
            bins op_write = {axil_register_transaction::WRITE};
        }

        cp_addr: coverpoint m_item.addr { // 为什么要将地址分为三段而不是直接一段判断完？
            bins low_range    = {[32'h0000_0000 : 32'h0000_0FFF]};
            bins mid_range    = {[32'h0000_1000 : 32'hFFFF_EFFF]};
            bins high_range   = {[32'hFFFF_F000 : 32'hFFFF_FFFF]};
        }

        cp_strb: coverpoint m_item.strb { // 为什么写掩码只有全1和独热码形式？其他形式呢？
            bins all_bytes = {4'b1111};
            bins single_byte = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
        }

        cross_op_addr: cross cp_operation, cp_addr; // 什么是交叉覆盖？      
    endgroup

    function new(string name = "axil_register_coverage", uvm_component parent);
            super.new(name, parent);
            axil_reg_cg = new();
    endfunction  

    virtual function void write(axil_register_transaction t);
        m_item = t;
        axil_reg_cg.sample(); // 这里是通过采样数据统计覆盖率吗？
    endfunction
endclass

`endif // AXIL_REGISTER_COVERAGE_SV