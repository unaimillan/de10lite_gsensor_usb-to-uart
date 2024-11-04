module stream_fifo
# (
    parameter width = 8, depth = 10
)
(
    input                clk,
    input                rst,

    input                up_valid,    // upstream
    output               up_ready,
    input  [width - 1:0] up_data,

    output               down_valid,  // downstream
    input                down_ready,
    output [width - 1:0] down_data,

    output logic [$clog2(width)-1:0] usage
);
    logic [$clog2(width)-1:0] next_usage;
    always_comb begin
        next_usage = usage;
        if (up_valid & up_ready)
            next_usage += 1'b1;
        if (down_valid & down_ready)
            next_usage -= 1'b1;
    end

    always_ff @( posedge clk or posedge rst ) begin : usage_ff
        if (rst)
            usage <= '0;
        else
            usage <= next_usage;
    end

    ff_fifo_wrapped_in_valid_ready # (
        .width (width), 
        .depth (depth)
    ) fifo (
        .clk        ( clk        ),
        .rst        ( rst        ),
        .up_valid   ( up_valid   ),    // upstream
        .up_ready   ( up_ready   ),
        .up_data    ( up_data    ),
        .down_valid ( down_valid ),  // downstream
        .down_ready ( down_ready ),
        .down_data  ( down_data  )
    ); 
endmodule
