module func(
    input clk,
    input rst,
    
    input [7:0] x1,
    input [7:0] x2,
    input start,
    
    output reg [3:0] y,
    output busy
);

reg [8:0] cbroot_arg;
reg cbroot_start;

wire cbroot_busy;
wire [2:0] cbroot_result;

cbroot crt(
    .clk(clk),
    .rst(rst),
    .x(cbroot_arg),
    .start(cbroot_start),
    .busy(cbroot_busy),
    .result(cbroot_result)
);

reg [7:0] smt1;
reg [7:0] smt2;
reg smt_start;
wire smt_busy;
wire [8:0] smt_result;

sum smt(
    .clk(clk),
    .rst(rst),
    .a(smt1),
    .b(smt2),
    .start(smt_start),
    .busy(smt_busy),
    .y(smt_result)
);

localparam debug = 0;

localparam IDLE = 0;
localparam INIT_CBROOT1 = 1;
localparam WAIT_CBROOT1 = 2;
localparam INIT_SUM = 3;
localparam WAIT_SUM = 4;
localparam INIT_CBROOT2 = 5;
localparam WAIT_CBROOT2 = 6;

reg [7:0] a, b;
reg [2:0] state;

assign busy = (state != IDLE);

always @(posedge clk)
    if (rst) begin
        y <= 0;
        state <= IDLE;
        a <= 0;
        b <= 0;
    end else begin
        case (state)
            IDLE:
                if (start) begin
                    state <= INIT_CBROOT1;
                    y <= 0;
                    a <= x1;
                    b <= x2;
                    
                    if (debug) $display("FUNC START, ARGUMENTS: %d, %d", x1, x2);
                end
            INIT_CBROOT1:
                begin
                    cbroot_arg <= b;
                    cbroot_start <= 1;
                    state <= WAIT_CBROOT1;
                end
            WAIT_CBROOT1:
                begin
                    if (cbroot_start) begin
                        cbroot_start <= 0;
                    end else if (~cbroot_busy) begin
                        state <= INIT_SUM;
                        if (debug) $display("FUNC CBROOT1: (%d)**1/3 = %d", cbroot_arg, cbroot_result);
                    end
                end
            INIT_SUM:
                begin
                    smt1 <= a;
                    smt2 <= cbroot_result;
                    smt_start <= 1;
                    state <= WAIT_SUM;
                end
            WAIT_SUM:
                begin
                    if (smt_start) begin
                        smt_start <= 0;
                    end else if (~smt_busy) begin
                        state <= INIT_CBROOT2;
                        if (debug) $display("FUNC SUM: %d + %d = %d", a, cbroot_result, smt_result);
                    end
                end
            INIT_CBROOT2:
                begin
                    cbroot_arg <= smt_result;
                    cbroot_start <= 1;
                    state <= WAIT_CBROOT2;
                end
            WAIT_CBROOT2:
                begin
                    if (cbroot_start) begin
                        cbroot_start <= 0;
                    end else if (~cbroot_busy) begin
                        y <= cbroot_result;
                        state <= IDLE;
                        if (debug) $display("FUNC CBROOT2: (%d)**1/3 = %d", smt_result, cbroot_result);
                    end
                end
            endcase
        end
endmodule

module cbroot(
    input clk,
    input rst,
    
    input [8:0] x,
    input start,
    
    output reg [2:0] result,
    output busy
);

localparam debug = 0;

localparam IDLE = 0;
localparam WORK_1 = 1;
localparam WORK_2 = 2;
localparam WORK_3 = 3;
localparam WORK_4 = 4;
localparam WORK_5 = 5;
localparam WORK_6 = 6;
localparam WAIT_S1 = 7;
localparam WAIT_S2 = 8;
localparam WAIT_M1 = 9;

reg [3:0] state;

reg signed [3:0] S;
reg [8:0] arg;
reg [8:0] b;
reg [3:0] res;
wire end_step;
wire continue_step;

reg [7:0] mlt1;
reg [7:0] mlt2;
reg mlt_start;
wire mlt_busy;
wire [15:0] mlt_result;


mul mlt(
    .clk(clk),
    .rst(rst),
    .a(mlt1),
    .b(mlt2),
    .start(mlt_start),
    .y(mlt_result),
    .busy(mlt_busy)
);

reg [7:0] smt1;
reg [7:0] smt2;
reg smt_start;
wire smt_busy;
wire [8:0] smt_result;

sum smt(
    .clk(clk),
    .rst(rst),
    .a(smt1),
    .b(smt2),
    .start(smt_start),
    .y(smt_result),
    .busy(smt_busy)
);

assign end_step = (S <= -3);
assign continue_step = (arg < b);
assign busy = (state != IDLE);

always @(posedge clk, posedge rst) begin
    if (rst) begin
        arg <= 0;
        b <= 0;
        res <= 0;
        S <= -4;
        result <= 0;
        state <= IDLE;
    end else begin
        case (state)
            IDLE:
                if (start) begin
                    state <= WORK_1;
                    arg <= x;
                    res <= 0;
                    S <= 6;
                    mlt_start <= 0;
                    smt_start <= 0;
                    result <= 0;
                    if (debug) $display("CBROOT START, ARGUMENT: %d, rst: %d, start: %d", x, rst, start);
                end
            WORK_1:
                begin
                    if (end_step) begin
                        state <= IDLE;
                        result <= res;
                        if (debug) $display("CBROOT RESULT: %d", result);
                    end else begin
                        if (debug) $display("CBROOT WORK1: res <<= 1 (%d -> %d)", res, res << 1);
                        res <= (res << 1);
                        state <= WORK_2;
                    end
                end
            WORK_2:
                begin
                    if (debug) $display("CBROOT WORK2: (%d) * (%d + 1)", res, res);
                    mlt1 <= res;
                    mlt2 <= res + 1;
                    mlt_start <= 1;
                    state <= WAIT_M1;
                end
            WAIT_M1:
                begin
                    if (mlt_start) begin
                        if (debug) $display("CBROOT MULTIPLICATION: %d * %d", mlt1, mlt2);
                        mlt_start <= 0;
                    end else if (~mlt_busy) begin
                        if (debug) $display("CBROOT MULTIPLICATION DONE: %d", mlt_result);
                        state <= WORK_3;
                    end
                end
            WORK_3:
                begin
                    if (debug) $display("CBROOT WORK3: 3 * (%d)", mlt_result);
                    smt1 <= mlt_result;
                    smt2 <= mlt_result << 1;
                    smt_start <= 1;
                    state <= WAIT_S1;
                end
            WAIT_S1:
                begin
                    if (smt_start) begin
                        if (debug) $display("CBROOT SUM1: %d + %d", smt1, smt2);
                        smt_start <= 0;
                    end else if (~smt_busy) begin
                        if (debug) $display("CBROOT SUM1 DONE: %d", smt_result);
                        state <= WORK_4;
                    end
                end
            WORK_4:
                begin
                    if (debug) $display("CBROOT WORK_4: b = (%d + 1) << %d = %d", smt_result, S, (smt_result + 1) << S);
                    b = (smt_result + 1) << S;
                    if (arg < b) begin
                        if (debug) $display("CBROOT WORK_4: x < b (%d < %d), continue for-loop", arg, b);
                        state <= WORK_6;
                    end else begin
                        if (debug) $display("CBROOT WORK_4: x = x - b (%d = %d - %d)", arg - b, arg, b);
                        arg <= arg - b;
                        state <= WORK_5;
                    end
                end
            WAIT_S2:
                begin
                    if (smt_start) begin
                        if (debug) $display("CBROOT SUM2: %d + %d", smt1, smt2);
                        smt_start <= 0;
                    end else if (~smt_busy) begin
                        if (debug) $display("CBROOT SUM2 DONE: %d", smt_result);
                        state <= WORK_5;
                    end
                end
            WORK_5:
                begin
                   if (debug) $display("CBROOT WORK_5: res += 1 (%d -> %d)", res, res + 1);
                   res <= res + 1;
                   state <= WORK_6;
                end 
            WORK_6:
                begin
                    if (debug) $display("CBROOT WORK_6: S -= 3 (%d -> %d)", S, S - 3);
                    S <= S - 3;
                    state <= WORK_1;
                end
        endcase
//        $display("State: %d", state);
//        $display("State: %d, arg=%d, b=%d, s=%d, res=%d, result=%d, rst=%d, start=%d, busy=%d", state, arg, b, S, res, result, rst, start, busy);
    end     
end
                      
endmodule

module mul(
    input clk,
    input rst,
    
    input [7:0] a,
    input [7:0] b,
    input start,
    
    output wire busy,
    output reg [15:0] y
);

localparam debug = 0;

localparam IDLE = 1'b0;
localparam WORK = 1'b1;

reg [2:0] ctr;
wire [2:0] end_step;
wire [7:0] part_sum;
wire [15:0] shifted_part_sum;
reg [7:0] ax, bx;
reg [15:0] part_res;
reg state;

assign part_sum = ax & { 8{ bx[ctr] }};
assign shifted_part_sum = part_sum << ctr;
assign end_step = (ctr == 3'h7);
assign busy = state;

always @(posedge clk)
    if (rst) begin
        ctr <= 0;
        part_res <= 0;
        y <= 0;
        state <= IDLE;
        if (debug) $display("MUL: reset");
    end else begin
        case (state)
            IDLE: 
                if (start) begin
                    state <= WORK;     
                    ax <= a;
                    bx <= b;
                    ctr <= 0;
                    part_res <= 0;
                    y <= 0;
                    if (debug) $display("MUL: start mul");
                end
            WORK:
                begin
                    if (end_step) begin
                        state <= IDLE;
                        y <= part_res;
                        if (debug) $display("MUL: %d * %d = %d", a, b, part_res);
                    end
                    
                    part_res <= part_res + shifted_part_sum;
                    ctr <= ctr + 1;
                end
        endcase
    end
endmodule

module sum(
    input clk,
    input rst,
    input start,
    input [7:0] a,
    input [7:0] b,
    output wire busy,
    output reg [8:0] y
);

localparam IDLE = 1'b0;
localparam WORK = 1'b1;

reg state;
reg [8:0] y_inh;

assign busy = state;

always @(posedge clk)
    if (rst) begin
        y_inh <= 0;
        y <= 0;
        state <= IDLE;
    end else begin
        case (state)
            IDLE: 
                if (start) begin
                    y_inh <= 0;
                    y <= 0;
                    state <= WORK;
                end
            WORK:
                begin
                    y <= a + b;
                    state <= IDLE;
                end
        endcase
    end
endmodule