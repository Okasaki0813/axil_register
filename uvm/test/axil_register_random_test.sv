class axil_register_random_test extends axil_register_base_test;
    `uvm_component_utils(axil_register_random_test)

    function new(string name = "axil_register_random_test", uvm_component parent); // test的父组件是uvm_top
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axil_register_random_virt_seq vseq = axil_register_random_virt_seq::type_id::create("vseq"); // create函数是工厂提供的，其作用是创造一个类型为random_virt_seq，名字为vseq的实例化类
        phase.raise_objection(this);
        vseq.start(env.virt_sqr); // 这句代码的意思是驱动env中的virt_sqr开始运行这个激励
        phase.drop_objection(this);
    endtask
endclass