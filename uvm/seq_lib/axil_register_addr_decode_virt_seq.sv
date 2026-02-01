`ifndef AXIL_REGISTER_ADDR_DECODE_VIRT_SEQ_SV
`define AXIL_REGISTER_ADDR_DECODE_VIRT_SEQ_SV

// 地址译码虚拟序列 - 测试不同地址范围和字对齐
class axil_register_addr_decode_virt_seq extends axil_register_base_virtual_sequence;
    `uvm_object_utils(axil_register_addr_decode_virt_seq)

    function new(string name = "axil_register_addr_decode_virt_seq");
        super.new(name);
    endfunction

    virtual task body();
        int test_count = 0;
        int pass_count = 0;

        `uvm_info(get_type_name(), "Starting Address Decode Test...", UVM_LOW)

        // Debug: 打印虚拟 sequencer 中的 agt_sqr 是否已被连接
        if (p_sequencer == null) begin
            `uvm_error(get_type_name(), "p_sequencer is null!")
        end else begin
            `uvm_info(get_type_name(), $sformatf("virtual sequencer p_sequencer name = %s", p_sequencer.get_full_name()), UVM_LOW)
            if (p_sequencer.agt_sqr == null) begin
                `uvm_error(get_type_name(), "p_sequencer.agt_sqr is null! Driver sequencer may not be connected.")
            end else begin
                `uvm_info(get_type_name(), $sformatf("agt_sqr name = %s", p_sequencer.agt_sqr.get_full_name()), UVM_LOW)
            end
        end

        // ========== 第一部分：合法地址范围（0x0000_0000 ~ 0x0000_3FFF）- 期望 OKAY ==========

        // 测试 1: 基本合法地址写入和读取（地址 0）
        test_count++;
        test_write_read_addr_expect_resp(32'h0000_0000, 32'hDEAD_BEEF, 4'hF, 2'b00, pass_count);

        // 测试 2: 合法范围内的中间地址
        test_count++;
        test_write_read_addr_expect_resp(32'h0000_2000, 32'hCAFE_BABE, 4'hF, 2'b00, pass_count);

        // 测试 3: 合法范围上界（0x0000_3FFF）
        test_count++;
        test_write_read_addr_expect_resp(32'h0000_3FFC, 32'h1234_5678, 4'hF, 2'b00, pass_count);

        // 测试 4: 合法范围内的部分字写入 - 低字节
        test_count++;
        test_write_read_addr_expect_resp(32'h0000_0004, 32'hXXXX_00FF, 4'b0011, 2'b00, pass_count);

        // 测试 5: 合法范围内的部分字写入 - 高字节
        test_count++;
        test_write_read_addr_expect_resp(32'h0000_0008, 32'hFF00_XXXX, 4'b1100, 2'b00, pass_count);

        // 测试 6: 合法范围内的随机地址扫描（10 个随机地址）
        repeat(10) begin
            bit [31:0] rand_addr;
            bit [31:0] rand_data;
            bit [3:0] rand_strb;
            
            if (!std::randomize(rand_addr) || !std::randomize(rand_data) || !std::randomize(rand_strb)) begin
                `uvm_error(get_type_name(), "Randomization failed")
            end else begin
                // 限制随机地址在合法范围内（0x0000_0000 ~ 0x0000_3FFC）
                rand_addr = {14'b0, rand_addr[13:2], 2'b00}; // 保证在 0x0~0x3FFC 范围且 4 字节对齐
                test_count++;
                test_write_read_addr_expect_resp(rand_addr, rand_data, rand_strb, 2'b00, pass_count);
            end
        end

        // ========== 第二部分：超界地址范围（> 0x0000_3FFF）- 期望 DECERR ==========

        // 测试 7: 超界地址（0x0000_4000）- 应返回 DECERR
        test_count++;
        test_write_read_addr_expect_resp(32'h0000_4000, 32'hBEEF_DEAD, 4'hF, 2'b10, pass_count);

        // 测试 8: 更高的超界地址（0xFFFF_FFFC）- 应返回 DECERR
        test_count++;
        test_write_read_addr_expect_resp(32'hFFFF_FFFC, 32'h9999_8888, 4'hF, 2'b10, pass_count);

        // 测试 9: 随机超界地址扫描（5 个随机超界地址）
        repeat(5) begin
            bit [31:0] rand_addr;
            bit [31:0] rand_data;
            bit [3:0] rand_strb;
            
            if (!std::randomize(rand_addr) || !std::randomize(rand_data) || !std::randomize(rand_strb)) begin
                `uvm_error(get_type_name(), "Randomization failed")
            end else begin
                // 生成超界地址：从 0x4000 到 0xFFFF_FFFC
                // 保证地址高位为1，使其 >= 0x4000 且 4 字节对齐
                rand_addr = {rand_addr[31:15], 1'b1, rand_addr[14:2], 2'b00};
                test_count++;
                test_write_read_addr_expect_resp(rand_addr, rand_data, rand_strb, 2'b10, pass_count);
            end
        end

        // 打印测试总结
        `uvm_info(get_type_name(), $sformatf("Address Decode Test Summary: %0d/%0d tests passed", 
            pass_count, test_count), UVM_LOW)

        if (pass_count == test_count) begin
            `uvm_info(get_type_name(), "All Address Decode Tests PASSED", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("%0d tests FAILED", test_count - pass_count))
        end
    endtask

    // 辅助任务：测试写入和读取指定地址，并验证预期的响应码
    virtual task test_write_read_addr_expect_resp(
        bit [31:0] addr, 
        bit [31:0] data, 
        bit [3:0] strb,
        bit [1:0] expected_resp,  // 期望的响应码 (OKAY=2'b00 或 DECERR=2'b10)
        output int pass_count     // 输出参数：通过的测试数
    );
    
        axil_register_write_seq wr_seq;
        axil_register_read_seq  rd_seq;
        string resp_name = (expected_resp == 2'b00) ? "OKAY" : "DECERR";

        `uvm_info(get_type_name(), $sformatf("Test: Write to addr 0x%08X, data 0x%08X, strb 4'b%b, expect %s", 
            addr, data, strb, resp_name), UVM_LOW)

        // 执行写操作
        wr_seq = axil_register_write_seq::type_id::create("wr_seq");
        wr_seq.addr = addr;
        wr_seq.data = data;
        wr_seq.strb = strb;
        wr_seq.start(p_sequencer.agt_sqr);  // 直接在 agt_sqr 上启动序列
        
        // 驱动已经完成握手，请求 transaction 中包含响应数据
        // 验证写响应
        if (wr_seq.req.resp !== expected_resp) begin
            `uvm_error(get_type_name(), $sformatf("Write to addr 0x%08X returned RESP=%0d (expected %s/%02b)", 
                addr, wr_seq.req.resp, resp_name, expected_resp))
        end else begin
            `uvm_info(get_type_name(), $sformatf("Write Response: %s ?", resp_name), UVM_LOW)
            pass_count++;
        end

        // 执行读操作
        rd_seq = axil_register_read_seq::type_id::create("rd_seq");
        rd_seq.addr = addr;
        rd_seq.start(p_sequencer.agt_sqr);  // 直接在 agt_sqr 上启动序列
        
        // 驱动已经完成握手，请求 transaction 中包含响应数据和读出的数据
        // 验证读响应
        if (rd_seq.req.resp !== expected_resp) begin
            `uvm_error(get_type_name(), $sformatf("Read from addr 0x%08X returned RESP=%0d (expected %s/%02b)", 
                addr, rd_seq.req.resp, resp_name, expected_resp))
        end else begin
            if (expected_resp == 2'b00) begin
                `uvm_info(get_type_name(), $sformatf("Read Response: %s, Data: 0x%08X ?", resp_name, rd_seq.req.data), UVM_LOW)
            end else begin
                `uvm_info(get_type_name(), $sformatf("Read Response: %s ?", resp_name), UVM_LOW)
            end
            pass_count++;
        end
    endtask

endclass

`endif // AXIL_REGISTER_ADDR_DECODE_VIRT_SEQ_SV