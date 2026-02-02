# axil_register
a testbench for register run on the basis of AXI4-Lite and UVM, using SystemVerilog

这份代码用于验证由Alex Forencich编写的基于AXI4-Lite协议运行的寄存器的各项功能，代码基于SystemVerilog语言和UVM验证方法学编写而成。

以下是目前已编写并成功跑通的测试（相关文件在 `uvm/test/`，激励序列在 `uvm/seq_lib/`）：

- 基础与环境验证
	- `axil_register_base_test.sv`: 基础测试基类，负责创建 `axil_register_env` 并下发通用配置，打印 UVM 层级结构，供其它具体测试继承。

- 冒烟测试（功能通路）
	- `axil_register_smoke_test.sv` / `axil_register_smoke_virt_seq.sv`
	- 验证主通路能进行最基本的写-读操作（写一个值到寄存器，再读回以确认数据一致）。

- 随机激励测试（稳健性）
	- `axil_register_random_test.sv` / `axil_register_random_virt_seq.sv`
	- 在一段地址范围内生成多组随机读写请求，覆盖不同地址和数据组合，增加对总线与寄存器实现鲁棒性的验证。

- Byte-strobe（WSTRB）专项测试
	- `axil_register_wstrb_test.sv` / `axil_register_wstrb_virt_seq.sv`
	- 验证局部字节写入（使用写使能/byte strobes）行为正确：先写入全字数据，再通过部分写（WSTRB）仅修改低字节，最后读回验证掩码生效。

- RAL（Register Abstraction Layer）功能测试
	- `axil_register_ral_test.sv` / `axil_register_ral_virt_seq.sv`
	- 使用 UVM RAL 接口做 frontdoor 读/写，并调用 `mirror()` 做模型与硬件的一致性检查。

- RAL 字段级测试
	- `axil_register_ral_field_test.sv` / `axil_register_ral_field_virt_seq.sv`
	- 验证对寄存器字段的局部更新流程：先设置初始值，再只更新某一字段（期望 Adapter 产生带 byte_en 的总线事务），最后使用 `mirror`/`update` 检查最终值。

- 复位/初始化测试（新增）
	- `axil_register_reset_test.sv` / `axil_register_reset_virt_seq.sv`
	- 验证全局复位（`rst` 信号）对系统的影响：施加复位并验证所有握手信号（valid/ready）是否正确回到初始状态。
	- **使用指南**: 详见 [RESET_TEST_GUIDE.md](RESET_TEST_GUIDE.md) 与 [RESET_TEST_QUICKREF.md](RESET_TEST_QUICKREF.md)

- 地址译码与非法地址处理测试（新增）（目前没跑通）
	- `axil_register_addr_decode_test.sv` / `axil_register_addr_decode_virt_seq.sv`
	- 验证不同地址范围的读写正确性、字对齐要求、部分字写入（WSTRB 掩码）、以及合法地址均返回 OKAY 响应。
	- **使用指南**: 详见 [ADDR_DECODE_TEST_GUIDE.md](ADDR_DECODE_TEST_GUIDE.md) 与 [ADDR_DECODE_TEST_QUICKREF.md](ADDR_DECODE_TEST_QUICKREF.md)

	配置说明（关于地址上限 `addr_limit`）:

	 - 驱动默认使用 `addr_limit = 32'h0000_3FFF`（历史兼容行为）。
	 - 若 DUT 能响应全 32 位地址空间，可在 top 或 test 中通过 `uvm_config_db` 覆盖该值：

	```systemverilog
	uvm_config_db#(logic[31:0])::set(0, "uvm_test_top.env.*", "addr_limit", 32'hFFFF_FFFF);
	```

	 - 更细粒度的覆盖可以把配置下发到具体路径，例如 `uvm_test_top.env.slv_agt.driver`。

	推荐：将 `addr_limit` 作为回归参数，以便在不同的 DUT 解码范围下运行相应的用例。

覆盖的 RTL 功能点（总结）

- AXI4-Lite 基本读写事务（address, write data, read data）
- 按字节掩码的部分写（byte strobe / WSTRB）行为
- 寄存器映射一致性（RAL 的 frontdoor/backdoor 路径，以及 mirror/check 功能）
- 随机/边界地址访问以增加时序与总线交互覆盖
- 通过 monitor/scoreboard 验证数据一致性和事务匹配
- **全局复位（NEW）**: 异步复位信号施加与释放后的状态初始化
- **地址译码（NEW）**: 不同地址空间的读写正确性和响应码验证（目前没跑通）