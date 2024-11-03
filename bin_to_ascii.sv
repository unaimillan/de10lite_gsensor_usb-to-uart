module bin_to_ascii_hex (
    input [3:0] binary,
    output logic [7:0] ascii_hex
);

    always_comb begin
        if (binary < 4'd10) ascii_hex = 8'd48 + 8'(binary);
        else                ascii_hex = 8'd55 + 8'(binary); // binary >= 10 == A => d65 + (binary - d10)
    end

endmodule
