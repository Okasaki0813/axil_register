class axil_register_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(axil_register_virtual_sequencer)
  
  axil_register_sequencer agt_sqr;

  function new (string name = "axil_register_virtual_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction
endclass