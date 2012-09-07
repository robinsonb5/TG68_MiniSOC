## Generated SDC file "hello_led.out.sdc"

## Copyright (C) 1991-2011 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 11.1 Build 216 11/23/2011 Service Pack 1 SJ Web Edition"

## DATE    "Fri Jul 06 23:05:47 2012"

##
## DEVICE  "EP3C25Q240C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk_50} -period 20.000 -waveform { 0.000 0.500 } [get_ports {clk_50}]


#**************************************************************
# Create Generated Clock
#**************************************************************

derive_pll_clocks


#**************************************************************
# Set Clock Latency
#**************************************************************


#**************************************************************
# Set Clock Uncertainty
#**************************************************************

derive_clock_uncertainty;


#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -clock { mypll|altpll_component|auto_generated|pll1|clk[1] } 2 [get_ports *sd1_data*]
set_input_delay -clock { mypll|altpll_component|auto_generated|pll1|clk[1] } 2 [get_ports *sd2_data*]

#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -clock { mypll|altpll_component|auto_generated|pll1|clk[1] } 4 [get_ports *sd1*]
set_output_delay -clock { mypll|altpll_component|auto_generated|pll1|clk[1] } 4 [get_ports *sd2*]

#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

