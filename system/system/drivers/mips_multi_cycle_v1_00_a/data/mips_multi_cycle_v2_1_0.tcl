##############################################################################
## Filename:          C:\Users\runarbol\Desktop\tdt4255\system\system/drivers/mips_multi_cycle_v1_00_a/data/mips_multi_cycle_v2_1_0.tcl
## Description:       Microprocess Driver Command (tcl)
## Date:              Thu Oct 03 11:25:25 2013 (by Create and Import Peripheral Wizard)
##############################################################################

#uses "xillib.tcl"

proc generate {drv_handle} {
  xdefine_include_file $drv_handle "xparameters.h" "mips_multi_cycle" "NUM_INSTANCES" "DEVICE_ID" "C_BASEADDR" "C_HIGHADDR" 
}
