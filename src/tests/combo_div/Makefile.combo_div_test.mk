# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM = icarus
TOPLEVEL_LANG = verilog

VERILOG_SOURCES = $(PWD)/tests/combo_div/combo_div_test_tb.v 
VERILOG_SOURCES += $(PWD)/combo_div.v

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = combo_div_test_tb

# MODULE is the basename of the Python test file
MODULE = combo_div_test
export PYTHONPATH := tests/combo_div:$(PYTHONPATH)

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim