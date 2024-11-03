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

    logic gff_x_ready, gff_y_ready, gff_z_ready;
    logic [15:0] gff_x, gff_y, gff_z;

    localparam MESSAGE_STR = "<xxxx|yyyy|zzzz>\n";
    localparam MESSAGE_SIZE = $size(MESSAGE_STR)/8;

    logic [MESSAGE_SIZE-1: 0][7:0] uart_message = MESSAGE_STR;

    assign uart_tx_valid = uart_tx_strobe;

     logic [$clog2(MESSAGE_SIZE) - 1:0] index;
     always_ff @ (posedge clk)
        if (rst)
            index <= '0;
        else if (uart_tx_valid) begin
            if (index == '0)
               index <= MESSAGE_SIZE - 1'b1;
            else
                index <= index - 1'b1;
        end
    
    logic [1:0] digit_counter;
    logic next_digit;
    logic current_digit_x, current_digit_y, current_digit_z;
    assign current_digit_x = uart_message[index] == "x";
    assign current_digit_y = uart_message[index] == "y";
    assign current_digit_z = uart_message[index] == "z";
    assign next_digit = uart_tx_valid & (current_digit_x | current_digit_y | current_digit_z);

    always_ff @ (posedge clk)
        if (rst)
            digit_counter <= 2'b11;
        else if ( next_digit )
            digit_counter <= digit_counter - 1'b1;
    
    assign gff_x_ready = digit_counter == 2'b00 & current_digit_x;
    assign gff_y_ready = digit_counter == 2'b00 & current_digit_y;
    assign gff_z_ready = digit_counter == 2'b00 & current_digit_z;

    logic [3:0] out_data_binary;
    logic [7:0] out_data_ascii;

    always_comb begin
        out_data_binary = '0;

        if (current_digit_x)
            out_data_binary = gff_x[4*digit_counter +: 4];

        if (current_digit_y)
            out_data_binary = gff_y[4*digit_counter +: 4];

        if (current_digit_z)
            out_data_binary = gff_z[4*digit_counter +: 4];
    end
    // assign out_data_binary = gdata_x[4*1 +: 4];
    

    bin_to_ascii_hex ibin (
        .binary(out_data_binary),
        .ascii_hex(out_data_ascii)
    );

    always_comb begin
        uart_tx_data = uart_message[index];
        if (next_digit) begin
            uart_tx_data = out_data_ascii;
        end
    end

    
    // always_comb begin
    //     uart_write = helloworld[index];
    //     if (uart_write == '0)
    //         uart_write = " ";
    //     uart_write = receive_data_r;
    //     if (8'd97 <= receive_data_r && receive_data_r <= 8'd122 ) begin
    //         uart_write = receive_data_r - 8'd32;
    //     end
    // end

	strobe_gen #(
        .strobe_hz(100)
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
        .UPDATE_FREQUENCY (5)
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
    
    ff_fifo_wrapped_in_valid_ready #(
        .width ( 16 )
    ) gdata_x_fifo (
        .clk ( clk ),
        .rst ( rst ),

        .up_valid ( gdata_valid ),
        .up_ready (),
        .up_data ( gdata_x ),

        .down_valid (  ),
        .down_ready ( gff_x_ready ),
        .down_data  ( gff_x )
    );

    ff_fifo_wrapped_in_valid_ready #(
        .width ( 16 )
    ) gdata_y_fifo (
        .clk ( clk ),
        .rst ( rst ),

        .up_valid ( gdata_valid ),
        .up_ready (),
        .up_data ( gdata_y ),

        .down_valid (  ),
        .down_ready ( gff_y_ready ),
        .down_data  ( gff_y )
    );

    ff_fifo_wrapped_in_valid_ready #(
        .width ( 16 )
    ) gdata_z_fifo (
        .clk ( clk ),
        .rst ( rst ),

        .up_valid ( gdata_valid ),
        .up_ready (),
        .up_data ( gdata_z ),

        .down_valid (  ),
        .down_ready ( gff_z_ready ),
        .down_data  ( gff_z )
    );

// ----------------------------------------------

    // logic uart_enable, enable_r;
    // logic [7:0] receive_data_r, receive_data;

    // uart_rx iuart_rx (
    //     .clk  (   clk ),
    //     .rstn ( ~ rst ),

    //     .i_uart_rx ( UART_RX ),

    //     .o_tready( '1 ),
    //     .o_tvalid( uart_enable ),
    //     .o_tdata ( receive_data   ),
        
    //     .o_overflow ( )
    // );

    // always_ff @ (posedge clk)
    //     if (rst)
    //         enable_r <= '0;
    //     else
    //         enable_r <= uart_enable;


    // always_ff @ (posedge clk)
    //     if (rst)
    //         receive_data_r <= '0;
    //     else if (uart_enable)
    //         receive_data_r <= receive_data;
    
    // assign LEDR = receive_data_r;

endmodule
