#############################
# User variables (可配置)
#############################
TESTNAME   ?= axil_register_smoke_test
SEED       ?= 1	# 随机种子（重现bug、回归测试）
GUI        ?= 0
COV        ?= 0
VERB       ?= UVM_HIGH
OUT        ?= out
# 输出目录

# Directory paths
PROJ_ROOT  = .
RTL_DIR    = $(PROJ_ROOT)/rtl
UVM_DIR    = $(PROJ_ROOT)/uvm

# Package files
VIP_PKG    = $(UVM_DIR)/vip_lib/axil_register_vip_pkg.sv
REG_PKG    = $(UVM_DIR)/reg/axil_register_reg_pkg.sv
SEQ_PKG    = $(UVM_DIR)/seq_lib/axil_register_seq_pkg.sv
ENV_PKG    = $(UVM_DIR)/env/axil_register_env_pkg.sv

# Top files
COV_FILE   = $(UVM_DIR)/cov/axil_register_coverage.sv
IF_FILE    = $(UVM_DIR)/tb/taxi_axil_if.sv
TOP_FILE   = $(UVM_DIR)/tb/axil_register_tb.sv
RTL_FILES  = $(wildcard $(RTL_DIR)/*.sv) # wildcard函数获取目录下所有符合模式的文件列表

# Test files (specific ones for better control)
TEST_FILES = $(UVM_DIR)/test/axil_register_base_test.sv \
             $(UVM_DIR)/test/axil_register_smoke_test.sv \

COV_OPTS = -cm line+cond+tgl+fsm+branch+assert

# Verilog Compilation Include directories
VCOMP_INC  = +incdir+$(RTL_DIR) \
             +incdir+$(UVM_DIR)/vip_lib \
             +incdir+$(UVM_DIR)/reg \
             +incdir+$(UVM_DIR)/env \
             +incdir+$(UVM_DIR)/seq_lib \
             +incdir+$(UVM_DIR)/test \
             +incdir+$(UVM_DIR)/cov \
             +incdir+$(UVM_DIR)/tb

# Conditional VCS options
VCS_OPTS =
ifeq ($(COV),1)
  VCS_OPTS += $(COV_OPTS)
endif

# Conditional run options
RUN_OPTS = +UVM_TESTNAME=$(TESTNAME) \
           +UVM_VERBOSITY=$(VERB) \
           +ntb_random_seed=$(SEED)

ifeq ($(COV),1)
  RUN_OPTS += $(COV_OPTS)
endif

ifeq ($(GUI),1)
  RUN_OPTS += -gui
endif

#############################
# Targets
#############################
.PHONY: all compile run clean cov

all: compile run

prepare:
	mkdir -p $(OUT)

compile: prepare
	vcs -full64 -sverilog -debug_access+all \
	-ntb_opts uvm-1.2 \
	-timescale=1ns/1ps \
	$(VCOMP_INC) \
	-assert svaext \
	$(VCS_OPTS) \
	$(RTL_FILES) \
	$(IF_FILE) \
	$(VIP_PKG) $(REG_PKG) $(COV_FILE) $(ENV_PKG) $(SEQ_PKG) \
	$(TEST_FILES) $(TOP_FILE) \
	-top axil_register_tb \
	-l "$(OUT)/vcs.log" \
	-o $(OUT)/simv
#	vcs将 Verilog/SystemVerilog 代码转换为二进制仿真文件（默认名为 simv）
# 	-full64指定编译器在64位模式下进行编译和仿真
# 	-sverilog启用SV支持
# 	-l vcs.log将编译过程中的所有提示、警告和错误信息保存到名为 vcs.log 的日志文件中
# 	-ntb_opts uvm: 这是 VCS 内置的 UVM 支持开关。它会自动链接 UVM 库，并预定义 UVM 相关的宏，省去了手动添加 UVM 源代码路径的麻烦。
# 	+incdir+$(UVM_DIR) / +incdir+$(SEQ_DIR) 等:
# 	+incdir+ 代表 Include Directory。
# 	当你在代码中使用 `include "file.sv" 时，编译器会去这些指定的目录下寻找该文件。
# 	-assert svaext: 启用 SystemVerilog 断言（SVA）的扩展功能支持。
# 	-top axil_register_tb: 显式指定仿真的顶层模块名为 axil_register_tb
# 	-o simv: 指定生成的二进制仿真可执行文件的名称。如果不指定，默认为 simv

run:
	cd $(OUT) && ./simv $(RUN_OPTS) -l run_$(TESTNAME)_$(SEED).log

cov:
	verdi -cov -covdir $(OUT)/simv.vdb
	
clean:
	rm -rf $(OUT) csrc simv* *.log *.vdb ucli.key


