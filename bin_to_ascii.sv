module bin_to_ascii_hex #(
    parameter HEX_DIGIT_W = 4,
    parameter BINARY_W = HEX_DIGIT_W*4
) (
    input [BINARY_W-1: 0] binary,
    output logic [HEX_DIGIT_W-1: 0][7:0] ascii_hex
);

    always_comb begin
        for (int digit = 0; digit < HEX_DIGIT_W; digit++) begin : digit_for
            ascii_hex[digit] = (binary[4*digit +: 4] < 4'd10) 
                ? 8'd48 + 8'(binary[4*digit +: 4]) 
                : 8'd55 + 8'(binary[4*digit +: 4]); // binary >= 10 == A => d65 + (binary - d10)
        end
    end

endmodule
