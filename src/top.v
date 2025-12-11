// DO NOT CHANGE THE NAME OR THE SIGNALS OF THIS MODULE
module top (
  input        clk,       
  input  [3:0] sw,        
  input  [3:0] btn,       
  output [7:0] led,       
  output [7:0] seven,     
  output [3:0] segment    
);






wire clockslower;
clk_divider #(
    .toggle_value(1_000_000) // 100MHz -> 50Hz
) clk_div_inst (
    .clk_in     (clk),
    .divided_clk(clockslower)
);



wire cleanreset, cleanstart, cleanpA, cleanpB;

debouncer db_rst (
    .clk       (clockslower),
    .rst       (1'b0),
    .noisy_in  (btn[2]),  // or (~btn[2]) if active-low
    .clean_out (cleanreset)
);

debouncer db_start (
    .clk       (clockslower),
    .rst       (1'b0),
    .noisy_in  (btn[1]),  // or (~btn[1])
    .clean_out (cleanstart)
);

debouncer db_pA (
    .clk       (clockslower),
    .rst       (1'b0),
    .noisy_in  (btn[3]),  // or (~btn[3])
    .clean_out (cleanpA)
);

debouncer db_pB (
    .clk       (clockslower),
    .rst       (1'b0),
    .noisy_in  (btn[0]),  // or (~btn[0])
    .clean_out (cleanpB)
);


wire [7:0] disp0_wire, disp1_wire, disp2_wire, disp3_wire;

battleship battleship_inst (
    .clk   (clockslower),
    .rst   (cleanreset),
    .start (cleanstart),
    .X     (sw[3:2]),
    .Y     (sw[1:0]),
    .pAb   (cleanpA),
    .pBb   (cleanpB),
    .disp0 (disp0_wire),
    .disp1 (disp1_wire),
    .disp2 (disp2_wire),
    .disp3 (disp3_wire),
    .led   (led)
);


ssd ssd_inst (
    .clk     (clk),           // fast clock
    .disp0   (disp0_wire),
    .disp1   (disp1_wire),
    .disp2   (disp2_wire),
    .disp3   (disp3_wire),
    .seven   (seven),
    .segment (segment)
);

endmodule
