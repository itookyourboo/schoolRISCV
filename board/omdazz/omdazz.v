
module omdazz
(
    input         clk,
    input         reset_n,
    input  [ 3:0] key_sw,
    output [ 3:0] led,
    output [ 7:0] abcdefgh,
    output [ 3:0] digit,
    output        buzzer
);
    // wires & inputs
    wire          clkCpu;
    wire          clkIn     =  clk;
    wire          rst_n     =  reset_n;
    wire          clkEnable =  key_sw[0];
    wire [  3:0 ] clkDevide =  4'b1000;
    wire [  4:0 ] regAddr   =  key_sw[1] ? 5'ha : 5'h0;
    wire [ 31:0 ] regData;

    //cores
    sm_top sm_top
    (
        .clkIn      ( clkIn     ),
        .rst_n      ( rst_n     ),
        .clkDevide  ( clkDevide ),
        .clkEnable  ( clkEnable ),
        .clk        ( clkCpu    ),
        .regAddr    ( regAddr   ),
        .regData    ( regData   )
    );

    //outputs
    assign led[0]    = ~clkCpu;
    assign led[3:1] = ~regData[2:0];

    //hex out
    wire [ 31:0 ] h7segment = regData;
    wire clkHex;

    sm_clk_divider hex_clk_divider
    (
        .clkIn   ( clkIn  ),
        .rst_n   ( rst_n  ),
        .devide  ( 4'b0   ),
        .enable  ( 1'b1   ),
        .clkOut  ( clkHex )
    );

    sm_hex_display_8 sm_hex_display_8
    (
        .clock          ( clkHex        ),
        .resetn         ( rst_n         ),
        .number         ( h7segment     ),
        .seven_segments ( abcdefgh[6:0] ),
        .dot            ( abcdefgh[7]   ),
        .anodes         ( digit         )
    );

    assign buzzer = 1'b1;

endmodule
