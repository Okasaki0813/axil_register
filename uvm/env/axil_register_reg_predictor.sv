`ifndef AXIL_REGISTER_REG_PREDICTOR_SV
`define AXIL_REGISTER_REG_PREDICTOR_SV

`include "uvm_macros.svh"

// 1. 导入必要的包（根据您的项目调整）
import uvm_pkg::*;

// 2. 导入您的transaction类（假设它叫axil_register_transaction）
`include "../../vip_lib/transactions/axil_register_transaction.sv"

// 3. 导入adapter（因为predictor需要相同的adapter）
`include "axil_register_reg_adapter.sv"

class axil_register_reg_predictor extends uvm_reg_predictor#(axil_register_transaction);
    `uvm_component_utils(axil_register_reg_predictor)

    bit enable_prediction = 1; // 是否启用预测功能
    bit debug_enable      = 0; // 是否启用调试输出

    int num_predicted_writes = 0; // 预测的写操作数量
    int num_predicted_reads  = 0; // 预测的读操作数量
    int num_predicted_errors = 0; // 预测的错误数量

    function new(string name = "axil_register_reg_predictor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void write(axil_register_transaction tr);
        if (!enable_prediction) begin
            `uvm_warning(get_type_name(), "Prediction is disabled, ignoring transaction")
            return;
        end

        super.write(tr); // 调用父类的写方法进行预测

        if (tr.operation == axil_register_transaction::WRITE) begin
            num_predicted_writes++;
            if (debug_enable) begin
                `uvm_info(get_type_name(), 
                    $sformatf("Predicted WRITE: addr=0x%0h, data=0x%0h, strb=0x%0h", 
                    tr.addr, tr.data, tr.strb), 
                    UVM_HIGH)
            end
        end else begin
            num_predicted_reads++;
            if (debug_enable) begin
                `uvm_info(get_type_name(), 
                    $sformatf("Predicted READ: addr=0x%0h, data=0x%0h", 
                    tr.addr, tr.data), 
                    UVM_HIGH)
            end
        end
    endfunction
endclass

`endif // AXIL_REGISTER_REG_PREDICTOR_SV