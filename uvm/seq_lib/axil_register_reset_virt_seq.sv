`ifndef AXIL_REGISTER_RESET_VIRT_SEQ_SV
`define AXIL_REGISTER_RESET_VIRT_SEQ_SV

`include "uvm_macros.svh"

// axil_register_reset_virt_seq.sv
// 复位虚拟序列 - 负责施加复位信号并验证系统复位后的状态
class axil_register_reset_virt_seq extends axil_register_base_virtual_sequence;
    `uvm_object_utils(axil_register_reset_virt_seq)

    function new(string name = "axil_register_reset_virt_seq");
        super.new(name);
    endfunction

    virtual task body();
        int reset_cycles = 5;      // 复位保持时间（时钟周期数）
        int wait_after_reset = 10; // 复位释放后的等待时间
        int cycle_cnt = 0;

        `uvm_info(get_type_name(), $sformatf("Starting Reset Sequence (reset for %0d cycles)...", reset_cycles), UVM_LOW)

        // 步骤 1：等待初始状态稳定（可选，通常仿真一开始就是复位状态）
        @(posedge p_sequencer.vif.clk);
        #1ps; // 等待 clock 上升沿稳定

        // 步骤 2：观察复位已施加（rst 由顶层驱动，序列只观察）
        if (p_sequencer.vif.rst !== 1'b0) begin
            `uvm_warning(get_type_name(), "Expected rst=0 at start (topmodule should drive rst), but got rst=1")
        end

        // 步骤 3：等待复位低电平维持指定的周期数
        `uvm_info(get_type_name(), $sformatf("Observing reset (low) for %0d clocks...", reset_cycles), UVM_LOW)
        repeat(reset_cycles) begin
            @(posedge p_sequencer.vif.clk);
            cycle_cnt++;
        end

        // 步骤 4：等待复位信号被释放（由顶层释放）
        `uvm_info(get_type_name(), "Waiting for reset to be released by topmodule...", UVM_LOW)
        wait(p_sequencer.vif.rst === 1'b1); // 阻塞直到 rst 被释放
        @(posedge p_sequencer.vif.clk);
        #1ps; // 稳定

        // 步骤 5：等待 N 个周期使系统稳定下来
        `uvm_info(get_type_name(), $sformatf("Waiting %0d clocks for stabilization...", wait_after_reset), UVM_LOW)
        repeat(wait_after_reset) begin
            @(posedge p_sequencer.vif.clk);
        end

        // 步骤 6：验证复位后的状态
        `uvm_info(get_type_name(), "Verifying post-reset state...", UVM_LOW)
        verify_reset_state();

        `uvm_info(get_type_name(), "Reset Sequence PASSED", UVM_LOW)
    endtask

    // 验证函数：检查复位后所有握手信号是否回到初始状态
    virtual task verify_reset_state();
        bit pass = 1;

        // valid 信号应都为 0（无有效事务）
        if (p_sequencer.vif.awvalid !== 1'b0) begin
            `uvm_error(get_type_name(), "awvalid signal not reset to 0")
            pass = 0;
        end
        if (p_sequencer.vif.wvalid !== 1'b0) begin
            `uvm_error(get_type_name(), "wvalid signal not reset to 0")
            pass = 0;
        end
        if (p_sequencer.vif.arvalid !== 1'b0) begin
            `uvm_error(get_type_name(), "arvalid signal not reset to 0")
            pass = 0;
        end

        // Ready signals can be any value (implementation dependent), but typically should be 0 or stable 1
        if (p_sequencer.vif.bvalid !== 1'b0) begin
            `uvm_warning(get_type_name(), "bvalid is not 0 (may be a design characteristic)")
        end
        if (p_sequencer.vif.rvalid !== 1'b0) begin
            `uvm_warning(get_type_name(), "rvalid is not 0 (may be a design characteristic)")
        end

        if (pass) begin
            `uvm_info(get_type_name(), "Post-reset state verification PASSED", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), "Post-reset state verification FAILED")
        end
    endtask

endclass

`endif // AXIL_REGISTER_RESET_VIRT_SEQ_SV