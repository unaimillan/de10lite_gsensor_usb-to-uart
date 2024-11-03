module top(
	input MAX10_CLK1_50,
	
	input [9  :0] SW,
	input [1  :0] KEY,
	
	output [9 :0] LEDR,
	inout  [35:0] GPIO
);
	wire clk = MAX10_CLK1_50;
	wire rst = SW[9];
	
	wire UART_TX;
	assign GPIO[0] = UART_TX;
	wire UART_RX = GPIO[1];

    logic uart_enable, enable_r;
    logic write_enable;
    logic [7:0] receive_data_r, receive_data;
    logic [7:0] send_data_r, send_data;

    uart_rx iuart_rx (
        .clk  (   clk ),
        .rstn ( ~ rst ),

        .i_uart_rx ( UART_RX ),

        .o_tready( '1 ),
        .o_tvalid( uart_enable ),
        .o_tdata ( receive_data   ),
        
        .o_overflow ( )
    );

    always_ff @ (posedge clk)
        if (rst)
            enable_r <= '0;
        else
            enable_r <= uart_enable;

    uart_tx  #(
		.FIFO_EA ( 10 )
	 ) iutx (
        .clk  (   clk ),
        .rstn ( ~ rst ),

        .o_uart_tx ( UART_TX ),

        .i_tready(  ),
        .i_tvalid( write_enable ),
        .i_tdata ( send_data   ),
        .i_tkeep ( '1 ),
        .i_tlast ( '1 )
    );
	 
     localparam MESSAGE_LEN = 20;
	 logic [0: MESSAGE_LEN-1][7:0] helloworld  = "Hello world!\n";

     logic [$clog2(MESSAGE_LEN) - 1:0] index;
     always_ff @ (posedge clk)
        if (rst)
            index <= 0;
        else if (write_enable)
            index <= index + 1'b1;

    always_comb begin
        send_data = helloworld[index];
        if (send_data == '0)
            send_data = " ";
    //     send_data = receive_data_r;
    //     if (8'd97 <= receive_data_r && receive_data_r <= 8'd122 ) begin
    //         send_data = receive_data_r - 8'd32;
    //     end
    end

    always_ff @ (posedge clk)
        if (rst)
            receive_data_r <= '0;
        else if (uart_enable)
            receive_data_r <= receive_data;
    
    assign LEDR = receive_data_r;

	strobe_gen #(
        .strobe_hz(10)
    ) stb (
		.clk(clk),
		.rst(rst),
		.strobe(write_enable)
	);

endmodule

module strobe_gen
# (
    parameter clk_mhz   = 50,
              strobe_hz = 3
)
(
    input        clk,
    input        rst,
    output logic strobe
);

    generate

        if (clk_mhz == 1)
        begin : if1

            assign strobe = 1'b1;

        end
        else
        begin : if0

            localparam period = clk_mhz * 1000 * 1000 / strobe_hz,
                       w_cnt  = $clog2 (period);

            logic [w_cnt - 1:0] cnt;

            always_ff @ (posedge clk or posedge rst)
                if (rst)
                begin
                    cnt    <= '0;
                    strobe <= '0;
                end
                else if (cnt == '0)
                begin
                    cnt    <= w_cnt' (period - 1);
                    strobe <= '1;
                end
                else
                begin
                    cnt    <= cnt - 1'd1;
                    strobe <= '0;
                end

        end

    endgenerate

endmodule
