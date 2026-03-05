vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xilinx_vip
vlib modelsim_lib/msim/xil_defaultlib
vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/axi_infrastructure_v1_1_0
vlib modelsim_lib/msim/axi_vip_v1_1_4
vlib modelsim_lib/msim/blk_mem_gen_v8_3_6
vlib modelsim_lib/msim/axi_bram_ctrl_v4_1_0
vlib modelsim_lib/msim/blk_mem_gen_v8_4_2
vlib modelsim_lib/msim/lib_cdc_v1_0_2
vlib modelsim_lib/msim/proc_sys_reset_v5_0_13

vmap xilinx_vip modelsim_lib/msim/xilinx_vip
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib
vmap xpm modelsim_lib/msim/xpm
vmap axi_infrastructure_v1_1_0 modelsim_lib/msim/axi_infrastructure_v1_1_0
vmap axi_vip_v1_1_4 modelsim_lib/msim/axi_vip_v1_1_4
vmap blk_mem_gen_v8_3_6 modelsim_lib/msim/blk_mem_gen_v8_3_6
vmap axi_bram_ctrl_v4_1_0 modelsim_lib/msim/axi_bram_ctrl_v4_1_0
vmap blk_mem_gen_v8_4_2 modelsim_lib/msim/blk_mem_gen_v8_4_2
vmap lib_cdc_v1_0_2 modelsim_lib/msim/lib_cdc_v1_0_2
vmap proc_sys_reset_v5_0_13 modelsim_lib/msim/proc_sys_reset_v5_0_13

vlog -work xilinx_vip -64 -incr -sv -L axi_vip_v1_1_4 -L xilinx_vip "+incdir+C:/Xilinx/Vivado/2018.3/data/xilinx_vip/include" \
"C:/Xilinx/Vivado/2018.3/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"C:/Xilinx/Vivado/2018.3/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"C:/Xilinx/Vivado/2018.3/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"C:/Xilinx/Vivado/2018.3/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"C:/Xilinx/Vivado/2018.3/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"C:/Xilinx/Vivado/2018.3/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"C:/Xilinx/Vivado/2018.3/data/xilinx_vip/hdl/axi_vip_if.sv" \
"C:/Xilinx/Vivado/2018.3/data/xilinx_vip/hdl/clk_vip_if.sv" \
"C:/Xilinx/Vivado/2018.3/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xil_defaultlib -64 -incr -sv -L axi_vip_v1_1_4 -L xilinx_vip "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/ec67/hdl" "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/85a3" "+incdir+C:/Xilinx/Vivado/2018.3/data/xilinx_vip/include" \
"C:/Xilinx/Vivado/2018.3/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Xilinx/Vivado/2018.3/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93 \
"C:/Xilinx/Vivado/2018.3/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work axi_infrastructure_v1_1_0 -64 -incr "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/ec67/hdl" "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/85a3" "+incdir+C:/Xilinx/Vivado/2018.3/data/xilinx_vip/include" \
"../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work xil_defaultlib -64 -incr -sv -L axi_vip_v1_1_4 -L xilinx_vip "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/ec67/hdl" "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/85a3" "+incdir+C:/Xilinx/Vivado/2018.3/data/xilinx_vip/include" \
"../../../bd/verif_data_packet_write/ip/verif_data_packet_write_axi_vip_0_0/sim/verif_data_packet_write_axi_vip_0_0_pkg.sv" \

vlog -work axi_vip_v1_1_4 -64 -incr -sv -L axi_vip_v1_1_4 -L xilinx_vip "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/ec67/hdl" "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/85a3" "+incdir+C:/Xilinx/Vivado/2018.3/data/xilinx_vip/include" \
"../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/98af/hdl/axi_vip_v1_1_vl_rfs.sv" \

vlog -work xil_defaultlib -64 -incr -sv -L axi_vip_v1_1_4 -L xilinx_vip "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/ec67/hdl" "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/85a3" "+incdir+C:/Xilinx/Vivado/2018.3/data/xilinx_vip/include" \
"../../../bd/verif_data_packet_write/ip/verif_data_packet_write_axi_vip_0_0/sim/verif_data_packet_write_axi_vip_0_0.sv" \

vlog -work blk_mem_gen_v8_3_6 -64 -incr "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/ec67/hdl" "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/85a3" "+incdir+C:/Xilinx/Vivado/2018.3/data/xilinx_vip/include" \
"../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/2751/simulation/blk_mem_gen_v8_3.v" \

vcom -work axi_bram_ctrl_v4_1_0 -64 -93 \
"../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/27fe/hdl/axi_bram_ctrl_v4_1_rfs.vhd" \

vcom -work xil_defaultlib -64 -93 \
"../../../bd/verif_data_packet_write/ip/verif_data_packet_write_axi_bram_ctrl_0_0/sim/verif_data_packet_write_axi_bram_ctrl_0_0.vhd" \

vlog -work blk_mem_gen_v8_4_2 -64 -incr "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/ec67/hdl" "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/85a3" "+incdir+C:/Xilinx/Vivado/2018.3/data/xilinx_vip/include" \
"../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/37c2/simulation/blk_mem_gen_v8_4.v" \

vlog -work xil_defaultlib -64 -incr "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/ec67/hdl" "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/85a3" "+incdir+C:/Xilinx/Vivado/2018.3/data/xilinx_vip/include" \
"../../../bd/verif_data_packet_write/ip/verif_data_packet_write_blk_mem_gen_0_0/sim/verif_data_packet_write_blk_mem_gen_0_0.v" \
"../../../bd/verif_data_packet_write/ip/verif_data_packet_write_clk_wiz_0/verif_data_packet_write_clk_wiz_0_clk_wiz.v" \
"../../../bd/verif_data_packet_write/ip/verif_data_packet_write_clk_wiz_0/verif_data_packet_write_clk_wiz_0.v" \

vcom -work lib_cdc_v1_0_2 -64 -93 \
"../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/ef1e/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_13 -64 -93 \
"../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/8842/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93 \
"../../../bd/verif_data_packet_write/ip/verif_data_packet_write_rst_clk_wiz_100M_0/sim/verif_data_packet_write_rst_clk_wiz_100M_0.vhd" \

vlog -work xil_defaultlib -64 -incr "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/ec67/hdl" "+incdir+../../../../incident_iq.srcs/data_packaging/bd/verif_data_packet_write/ipshared/85a3" "+incdir+C:/Xilinx/Vivado/2018.3/data/xilinx_vip/include" \
"../../../bd/verif_data_packet_write/sim/verif_data_packet_write.v" \

vlog -work xil_defaultlib \
"glbl.v"

