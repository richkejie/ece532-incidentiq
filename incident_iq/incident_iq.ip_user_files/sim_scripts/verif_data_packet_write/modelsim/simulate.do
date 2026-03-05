onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -t 1ps -L xilinx_vip -L xil_defaultlib -L xpm -L axi_infrastructure_v1_1_0 -L axi_vip_v1_1_4 -L blk_mem_gen_v8_3_6 -L axi_bram_ctrl_v4_1_0 -L blk_mem_gen_v8_4_2 -L lib_cdc_v1_0_2 -L proc_sys_reset_v5_0_13 -L xilinx_vip -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.verif_data_packet_write xil_defaultlib.glbl

do {wave.do}

view wave
view structure
view signals

do {verif_data_packet_write.udo}

run -all

quit -force
