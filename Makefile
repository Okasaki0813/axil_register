RTL_DIR  = ./rtl
UVM_DIR  = ./uvm
SEQ_DIR  = ./uvm/seq_lib
TEST_DIR = ./uvm/test
REG_DIR  = ./uvm/reg
ENV_DIR  = ./uvm/env

all: clean compile run

RTL_FILES = $(RTL_DIR)/taxi_axil_register.sv \
			$(RTL_DIR)/taxi_axil_register_wr.sv \
			$(RTL_DIR)/taxi_axil_register_rd.sv

UVM_FILES = $(UVM_DIR)/axil_register_transaction.sv \
			$(UVM_DIR)/taxi_axil_if.sv \
			$(UVM_DIR)/axil_register_sequencer.sv \
			$(UVM_DIR)/axil_register_virtual_sequencer.sv \
			$(UVM_DIR)/axil_register_driver.sv \
			$(UVM_DIR)/axil_slave_driver.sv \
			$(UVM_DIR)/axil_register_monitor.sv \
			$(UVM_DIR)/axil_register_agent.sv \
			$(UVM_DIR)/axil_register_coverage.sv 

REG_FILES = $(REG_DIR)/axil_register_reg_data.sv \
            $(REG_DIR)/axil_register_reg_block.sv

ENV_FILES = $(ENV_DIR)/axil_register_reg_adapter.sv \
			$(ENV_DIR)/axil_register_scoreboard.sv \
			$(ENV_DIR)/axil_register_env.sv


SEQ_FILES = $(SEQ_DIR)/axil_register_base_virtual_sequence.sv \
            $(SEQ_DIR)/axil_register_write_seq.sv \
            $(SEQ_DIR)/axil_register_read_seq.sv \
            $(SEQ_DIR)/axil_register_smoke_virt_seq.sv \
            $(SEQ_DIR)/axil_register_random_virt_seq.sv \
			$(SEQ_DIR)/axil_register_ral_virt_seq.sv \
			$(SEQ_DIR)/axil_register_wstrb_virt_seq.sv \
            $(SEQ_DIR)/axil_register_sequence.sv \
			$(SEQ_DIR)/axil_register_ral_field_virt_seq.sv
			
TEST_FILES = $(TEST_DIR)/axil_register_base_test.sv \
             $(TEST_DIR)/axil_register_smoke_test.sv \
             $(TEST_DIR)/axil_register_random_test.sv \
			 $(TEST_DIR)/axil_register_ral_test.sv \
			 $(TEST_DIR)/axil_register_wstrb_test.sv \
			 $(TEST_DIR)/axil_register_ral_field_test.sv

TOP_FILES = $(UVM_DIR)/axil_register_top.sv

COV_OPTS = -cm line+cond+tgl+fsm+branch+assert

compile:
	vcs -full64 -sverilog -debug_access+all \
	-ntb_opts uvm \
	-timescale=1ns/1ps \
	+incdir+$(UVM_DIR) \
	+incdir+$(REG_DIR) \
	+incdir+$(ENV_DIR) \
	+incdir+$(SEQ_DIR) \
	+incdir+$(TEST_DIR) \
	-assert svaext \
	$(COV_OPTS) \
	$(RTL_FILES) \
	$(UVM_FILES) \
	$(REG_FILES) \
	$(ENV_FILES) \
	$(SEQ_FILES) \
	$(TEST_FILES) \
	$(TOP_FILES) \
	-top top \
	-l vcs.log \
	-o simv
#	vcs将 Verilog/SystemVerilog 代码转换为二进制仿真文件（默认名为 simv）
# 	-full64指定编译器在64位模式下进行编译和仿真
# 	-sverilog启用SV支持
# 	-l vcs.log将编译过程中的所有提示、警告和错误信息保存到名为 vcs.log 的日志文件中
# 	-ntb_opts uvm: 这是 VCS 内置的 UVM 支持开关。它会自动链接 UVM 库，并预定义 UVM 相关的宏，省去了手动添加 UVM 源代码路径的麻烦。
# 	+incdir+$(UVM_DIR) / +incdir+$(SEQ_DIR) 等:
# 	+incdir+ 代表 Include Directory。
# 	当你在代码中使用 `include "file.sv" 时，编译器会去这些指定的目录下寻找该文件。
# 	-assert svaext: 启用 SystemVerilog 断言（SVA）的扩展功能支持。
# 	-top top: 显式指定仿真的顶层模块名为 top（对应你 axil_register_top.sv 中的 module top）。
# 	-o simv: 指定生成的二进制仿真可执行文件的名称。如果不指定，默认为 simv。

run:
	./simv +UVM_TESTNAME=axil_register_ral_field_test \
	+UVM_VERBOSITY=UVM_HIGH \
	$(COV_OPTS) \
	 -l run.log

cov:
	verdi -cov -covdir simv.vdb &
	
clean:
	rm -rf csrc simv* *.log *.vdb ucli.key vc_hdrs.h


