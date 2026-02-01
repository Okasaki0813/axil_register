`include "uvm_macros.svh"

class axil_register_agent extends uvm_agent;
    `uvm_component_utils(axil_register_agent)

    virtual taxi_axil_if    vif;

    axil_register_sequencer sqr;
    axil_register_driver    drv;
    axil_register_monitor   mon;

    function new(string name = "axil_register_agent", uvm_component parent);
        super.new(name, parent);        
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual taxi_axil_if)::get(this, "", "vif", vif)) begin  // get()中的四个参数分别是什么意思？
                                                                                    // this是当前组件（即monitor的指针）
                                                                                    // “”是寻找该文件的指定路径
                                                                                    // “vif”是要找的文件的名字
                                                                                    // vif是虚拟接口句柄
            `uvm_fatal("NOVIF", $sformatf("vif not found at path: %s", get_full_name()))
        end

        mon = axil_register_monitor::type_id::create("mon", this); // 为什么这里的create方法中有第二个参数this？它是干嘛用的？
                                                                   // this用于指示mon组件的父组件，方便编译器在uvm的层级树中找到它

        if(get_is_active() == UVM_ACTIVE) begin // get_is_active()和UVM_ACTIVE分别是uvm_agent内置的函数和参数吗？是的
            sqr = axil_register_sequencer::type_id::create("sqr", this);
            drv = axil_register_driver::type_id::create("drv", this);
        end
    endfunction

    extern virtual function void connect_phase(uvm_phase phase); // 为什么这个函数不在类内实现，而要在类外实现？
endclass

function void axil_register_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (get_is_active() == UVM_ACTIVE) begin
        drv.vif = this.vif;
        drv.seq_item_port.connect(sqr.seq_item_export);
    end

    mon.vif = this.vif;
endfunction