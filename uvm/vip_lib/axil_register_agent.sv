`include "uvm_macros.svh"

// axil_register_agent (deprecated)
// 兼容包装: 保留原名 axil_register_agent 以避免第三方/旧代码立即失效。
// 推荐使用 `axil_register_master_agent`，此包装类继承自 `axil_register_master_agent` 并保持原默认名称。

class axil_register_agent extends axil_register_master_agent;
    `uvm_component_utils(axil_register_agent)

    function new(string name = "axil_register_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass