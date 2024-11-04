module top(
	input MAX10_CLK1_50,
	
	input [9  :0] SW,
	input [1  :0] KEY,
	
	output [9 :0] LEDR,
	inout  [35:0] GPIO,

    output GSENSOR_CS_N,
    output GSENSOR_SCLK,
    output GSENSOR_SDI,
    input  GSENSOR_SDO

);
	wire clk = MAX10_CLK1_50;
	wire rst = SW[9];
	
	wire UART_TX;
	assign GPIO[0] = UART_TX;
	wire UART_RX = GPIO[1];

    logic uart_tx_valid, uart_tx_strobe; // Strobe on specific freq.
    logic [7:0] uart_tx_data;

    logic gdata_valid;
    logic [15:0] gdata_x, gdata_y, gdata_z;

    logic fifo_xyz_valid, fifo_xyz_ready;
    logic [15:0] gff_x, gff_y, gff_z;

    localparam MESSAGE_FORMAT = "<xxxx|yyyy|zzzz>\n";
    localparam MESSAGE_SIZE = $size(MESSAGE_FORMAT)/8;

    logic [MESSAGE_SIZE-1: 0][7:0] uart_message;
    assign uart_message = { "<", out_ascii_x, "|", out_ascii_y, "|", out_ascii_z, ">\n" };
    // assert $size(uart_message) === MESSAGE_SIZE

    assign uart_tx_valid = uart_tx_strobe;

     logic [$clog2(MESSAGE_SIZE) - 1:0] message_idx;
     always_ff @ (posedge clk)
        if (rst)
            message_idx <= '0;
        else if (uart_tx_valid) begin
            if (message_idx == '0)
                message_idx <= MESSAGE_SIZE - 1'b1;
            else
                message_idx <= message_idx - 1'b1;
        end
    
    assign fifo_xyz_ready = message_idx == '0;

    logic [3:0][7:0] out_ascii_x, out_ascii_y, out_ascii_z;

    bin_to_ascii_hex convert_x (
        .binary(gff_x),
        .ascii_hex(out_ascii_x)
    );
    bin_to_ascii_hex convert_y (
        .binary(gff_y),
        .ascii_hex(out_ascii_y)
    );
    bin_to_ascii_hex convert_z (
        .binary(gff_z),
        .ascii_hex(out_ascii_z)
    );

    assign uart_tx_data = uart_message[message_idx];

    

	strobe_gen #(
        .strobe_hz( 1000 )
    ) stb (
		.clk    (            clk ),
		.rst    (            rst ),
		.strobe ( uart_tx_strobe )
	);

    uart_tx  #(
		.FIFO_EA ( 4 )
	 ) iutx (
        .clk  (   clk ),
        .rstn ( ~ rst ),

        .o_uart_tx ( UART_TX ),

        .i_tready(  ),
        .i_tvalid( uart_tx_valid ),
        .i_tdata ( uart_tx_data  ),
        .i_tkeep ( '1 ),
        .i_tlast ( '1 )
    );

    gsensor #(
        .UPDATE_FREQUENCY ( 50 )
    ) igsen (
        .clk( clk ),
        .reset_n ( ~ rst),

        .data_valid ( gdata_valid ),
        .data_x     (     gdata_x ),
        .data_y     (     gdata_y ),
        .data_z     (     gdata_z ),

        .SPI_CSN( GSENSOR_CS_N ),
        .SPI_CLK( GSENSOR_SCLK ),
        .SPI_SDI( GSENSOR_SDI  ),
        .SPI_SDO( GSENSOR_SDO  )
    );
    
    stream_fifo #(
        .width ( 16 )
    ) gdata_x_fifo (
        .clk ( clk ),
        .rst ( rst ),

        .up_valid ( gdata_valid ),
        .up_ready (),
        .up_data ( gdata_x ),

        .down_valid ( fifo_xyz_valid ),
        .down_ready ( fifo_xyz_ready ),
        .down_data  ( gff_x ),

        .usage ( LEDR )
    );

    stream_fifo #(
        .width ( 16 )
    ) gdata_y_fifo (
        .clk ( clk ),
        .rst ( rst ),

        .up_valid ( gdata_valid ),
        .up_ready (),
        .up_data ( gdata_y ),

        .down_valid (  ),
        .down_ready ( fifo_xyz_ready ),
        .down_data  ( gff_y )
    );

    stream_fifo #(
        .width ( 16 )
    ) gdata_z_fifo (
        .clk ( clk ),
        .rst ( rst ),

        .up_valid ( gdata_valid ),
        .up_ready (),
        .up_data  ( gdata_z ),

        .down_valid (  ),
        .down_ready ( fifo_xyz_ready ),
        .down_data  ( gff_z )
    );

endmodule
