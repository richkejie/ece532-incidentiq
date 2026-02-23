# ece532-incidentiq

This is repo for ECE532 Team No. 2: IncidentIQ

# nexys4_ddr board files (tutorial 3)

1. copy `imports/board_files/nexys4_ddr` to `<Vivado Install Directory>/Xilinx/Vivado/<Vivado Version>/data/boards/board_files`

2. Alternatively, via TCL console: `set_param board.repoPaths <path to extracted board files>/board_files/` (this adds board files to current instance of Vivado)

# Vivado SDK

1. Generate bitstream (after synthesis, implementation)
2. File-->Export-->Export Hardware (Include Bitstream)
3. File-->Launch SDK
