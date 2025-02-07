`ifndef SRC_SHIFT_DIV
`define SRC_SHIFT_DIV

module aidan_mcnay_shift_div #(
    parameter nbits = 16
) (
    input  wire               clk,
    input  wire               reset,
    
    input  wire [nbits - 1:0] opa,
    input  wire [nbits - 1:0] opb,
    input  wire               istream_val,
    output wire               istream_rdy,

    output wire [nbits - 1:0] result,
    output wire               ostream_val,
    input  wire               ostream_rdy
);

    // Performs opa/opb using shifting division with a 
    // latency-insensitive interface
    // Credit for idea: Quinn Caroline Guthrie <3

    // Define FSM states

    localparam IDLE      = 2'd0;
    localparam SHIFT_OPB = 2'd1;
    localparam CALC      = 2'd2;
    localparam DONE      = 2'd3;

    // Define datapath nets

    reg  [nbits-1:0] opa_reg;
    reg  [nbits-1:0] opb_reg;
    reg  [nbits-1:0] opb_value;

    wire [nbits-1:0] opb_reg_sl;
    assign opb_reg_sl = opb_reg << 1;

    //--------------------Control Logic--------------------

    // Define FSM transitions

    reg  [1:0] state_curr;
    reg  [1:0] state_next;

    always @( posedge clk ) begin
        state_curr <= state_next;
    end

    always @( * ) begin
        
        if( reset )
            state_next = IDLE;

        else if( state_curr == IDLE ) begin
            if( istream_val ) begin

                if( opb > opa ) // Early exit
                    state_next = DONE;

                else if( opb_reg[nbits-1] == 1 ) // Already shifted left
                    state_next = CALC;

                else state_next = SHIFT_OPB;
            end

            else state_next = state_curr;
        end

        else if( state_curr == SHIFT_OPB ) begin

            if( opb_reg[nbits-2] == 1'b1 ) // MSB will be 1 once shifted
                state_next = CALC;

            else if( opb_reg_sl > opa_reg ) // Don't need to shift any more after this
                state_next = CALC;

            else state_next = state_curr;
        end

        else if( state_curr == CALC ) begin
            if( opb_reg == opb_value )
                state_next = DONE;

            else if( opb_reg == opa_reg ) // Early exit
                state_next = DONE;

            else state_next = state_curr;
        end

        else if( state_curr == DONE ) begin
            if( ostream_rdy )
                state_next = IDLE;

            else state_next = state_curr;
        end

        else state_next = state_curr;
    end

    // Define interface outputs based on FSM state

    assign istream_rdy = ( state_curr == IDLE );
    assign ostream_val = ( state_curr == DONE );

    //--------------------Datapath--------------------

    // opa tracks the value that our final result will be
    always @( posedge clk ) begin
        if( reset ) opa_reg <= 0;

        else if( state_curr == IDLE ) begin
            opa_reg <= opa;
        end

        else if( state_curr == CALC ) begin
            if( opb_reg <= opa_reg ) begin // Need to subtract
                opa_reg <= ( opa_reg - opb_reg );
            end
        end
    end

    // opb keeps track of our current divisor
    always @( posedge clk ) begin
        if( reset ) opb_reg <= 0;

        else if( state_curr == IDLE ) begin
            opb_reg <= opb;
        end

        else if( state_curr == SHIFT_OPB ) begin
            opb_reg <= opb_reg_sl; // Shift left until the MSB is 1
        end

        else if( state_curr == CALC ) begin
            opb_reg <= ( opb_reg >> 1 ); // Shift right to divide opa
        end
    end

    // Keep track of our initial divisor with opb_value
    always @( posedge clk ) begin
        if( reset ) opb_value <= 0;

        else if( state_curr == IDLE ) opb_value <= opb;
    end

    // Our output will always be stored in the opa register
    assign result = opa_reg;

endmodule

`endif // SRC_SHIFT_DIV