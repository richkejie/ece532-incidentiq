# ece532-incidentiq

This is repo for ECE532 Team No. 2: IncidentIQ

# nexys4_ddr board files (tutorial 3)

1. copy `imports/board_files/nexys4_ddr` to `<Vivado Install Directory>/Xilinx/Vivado/<Vivado Version>/data/boards/board_files`

2. Alternatively, via TCL console: `set_param board.repoPaths <path to extracted board files>/board_files/` (this adds board files to current instance of Vivado)

# Vivado SDK

1. Generate bitstream (after synthesis, implementation)
2. File-->Export-->Export Hardware (Include Bitstream)
3. File-->Launch SDK

To make a new project:

1.  In Vivado SDK, File-->New-->Application Project
2.  Enter some project name
3.  Choose OS Platform to be Standalone
4.  Choose Next: can pick a template
5.  Finish

To run program:

1.  Run-->Run Configurations
2.  Choose Xilinx C/C++ Application (GDB)
3.  Click New (the file button with a +)
4.  Open Application Tab
5.  Click Browse next to Project Name; select desired program
6.  In Summary, click checkbox under Download column
7.  Click Apply to save the run
8.  Close
