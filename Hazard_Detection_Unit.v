module Hazard_Detection_Unit (
    // Inputs from ID/EX Pipeline Register (Execute Stage)
    input wire ID_EX_MemRead,              // 1 = Load instruction in EX stage
    input wire [1:0] ID_EX_Write_Reg_Addr, // Destination register of the load
    
    // Inputs from IF/ID Pipeline Register (Decode Stage)  
    input wire [1:0] IF_ID_Rs_Addr,        // Source register A of current instruction
    input wire [1:0] IF_ID_Rt_Addr,        // Source register B of current instruction
    
    // Output Control Signal
    output wire Stall                       // 1 = Stall pipeline, 0 = Continue
);
    assign Stall = ID_EX_MemRead &&  // Is there a Load in EX stage?
                   (                  // AND does current instruction need it?
                       (ID_EX_Write_Reg_Addr == IF_ID_Rs_Addr) ||  // Rs depends on load?
                       (ID_EX_Write_Reg_Addr == IF_ID_Rt_Addr)     // Rt depends on load?
                   );
endmodule
