`timescale 1ns / 1ps

module mul(
    input [31:0] A,
    input [31:0] B,
    output Exception,Overflow,Underflow,
    output [31:0] Result
    );
wire [8:0] exponent,sum_exponent;
wire [22:0] product_mantissa;
wire [47:0] product,product_normalised;
wire bitandA,bitandB,bitorA,bitorB,pro_man_bitand;
wire sign,product_round,normalised,zero,carry,sign_carry,not_zero,w1;
wire [31:0]ripple_result_1,ripple_result_2,ripple_result_3;

xor (sign,A[31],B[31]); // bit dấu của kết quả

// Nếu tất cả các bit exponent của bất kỳ số nào là 1 thì là Inf hoặc NaN. Exception được đặt thành 1
bitand_mul C1(.bitandin(A[30:23]),.bitandout(bitandA));
bitand_mul C2(.bitandin(B[30:23]),.bitandout(bitandB));
bitnor_mul A1(.in(A[30:23]),.bitnorout(bitnorA));
bitnor_mul A2(.in(B[30:23]),.bitnorout(bitnorB));
or(Exception,bitandA,bitandB,bitnorA,bitnorB); 
or(zero,bitnorA,bitnorB);

// nếu exponent không phải tất cả đều bằng 0 thì bit ẩn là 1
bitor_mul  C3(.bitorin(A[30:23]),.bitorout(bitorA));
bitor_mul  C4(.bitorin(B[30:23]),.bitorout(bitorB));

assign product = {bitorA,A[22:0]} * {bitorB,B[22:0]};

// làm tròn 23 bit cuối cùng
bitor2_mul C5(.in(product[22:0]),.out(product_round));  
// Nếu bit thứ 48 của tích là 1 thì tích được chuẩn hóa và bit này sẽ hoạt động như bit ẩn
and(normalised,product[47],1'b1);
// Nếu tích chưa được chuẩn hóa thì dịch trái tích
assign product_normalised = normalised ? product : product << 1;
// Mantissa cuối cùng
assign product_mantissa = product_normalised[46:24] + (product_normalised[23] & product_round);
// tích bằng 0 nếu tất cả các bit mantissa là 0
bitand2_mul C6(.in(product_mantissa[22:0]),.out(pro_man_bitand));

// Cộng 2 exponenta và trừ đi BIAS của nó 
adder8_mul  C8(.A(A[30:23]),.B(B[30:23]),.Cin(1'b0),.Sum(sum_exponent[7:0]),.Cout(sum_exponent[8]));
adder9_mul  C10( .A(sum_exponent[8:0]), .B(9'b110000001), .Cin(normalised),       .Sum(exponent[8:0]), .Cout(sign_carry));

// nếu sign_carry bằng 0 thì kết quả  giá trị âm và đây là hiện tượng Underflow. 
not(Underflow,sign_carry);
// Nếu sign_carry bằng 1 và bit thứ 9 của exponent cũng bằng 1, thì điều đó có nghĩa là kết quả là số dương nhưng số mũ đã vượt quá giới hạn của nó.
and(Overflow,sign_carry,exponent[8]);
// Nếu Exception = 1 thì gán 32'b0 cho kết quả
mux_multi_mul C13( .A({sign,exponent[7:0],product_mantissa}), .B(32'hffffffff),       .SL(Exception),    .O(ripple_result_1[31:0]));
// Nếu zero = 1 thì kết quả là số 0
mux_multi_mul C14( .A(ripple_result_1[31:0]),                 .B(32'h00000000), .SL(zero),         .O(ripple_result_2[31:0]));
// Nếu Overflow ở mức cao thì số mũ đã vượt quá giá trị của nó, tức là 8'b11111111."
mux_multi_mul C15( .A(ripple_result_2[31:0]),                 .B(32'hffffffff), .SL(Overflow),     .O(ripple_result_3[31:0]));
// Nếu Underflow ở mức cao thì số mũ vẫn còn âm.
mux_multi_mul C16( .A(ripple_result_3[31:0]),                 .B(32'h00000000), .SL(Underflow),    .O(Result[31:0])         );
// Nếu Exception, zero, Overflow và Underflow đều ở mức thấp thì kết quả sẽ được gán vào kết quả cuối cùng.
endmodule

module bitand_mul(
   input [7:0]bitandin,
   output bitandout
   );
and(bitandout,bitandin[7],bitandin[6],bitandin[5],bitandin[4],bitandin[3],bitandin[2],bitandin[1],bitandin[0]);
endmodule

module bitor_mul(
   input [7:0]bitorin,
   output bitorout
   );
or(bitorout,bitorin[7],bitorin[6],bitorin[5],bitorin[4],bitorin[3],bitorin[2],bitorin[1],bitorin[0]);
endmodule

module bitor2_mul(
   input [22:0]in,
   output out
   );
or(out,in[22],in[21],in[20],in[19],in[18],in[17],in[16],in[15],in[14],in[13],in[12],in[11],in[10],in[9],in[8],in[7],in[6],in[5],in[4],in[3],in[2],in[1],in[0]);
endmodule

module bitnor_mul(
   input [7:0]in,
   output bitnorout
   );
nor(bitnorout,in[7],in[6],in[5],in[4],in[3],in[2],in[1],in[0]);
endmodule

module bitand2_mul(
   input [22:0]in,
   output out
   );
and(out,in[22],in[21],in[20],in[19],in[18],in[17],in[16],in[15],in[14],in[13],in[12],in[11],in[10],in[9],in[8],in[7],in[6],in[5],in[4],in[3],in[2],in[1],in[0]);
endmodule

module adder_half_mul(
   input a,
   input b,
   output sum,
   output carry
   );
xor(sum,a,b);
and(carry,a,b);
endmodule

module adder_full_mul(
   input a,
   input b,
   input cin,
   output sum,
   output carry
   );
wire w1,w2,w3;
adder_half_mul H0(.a(a),    .b(b),    .sum(w1),   .carry(w2));
adder_half_mul H1(.a(w1),   .b(cin),  .sum(sum),  .carry(w3));
or(carry,w2,w3);
endmodule

module adder4_mul(
   input [3:0]a,
   input [3:0]b,
   input cin,
   output [3:0]sum,
   output carry
   );
wire w1,w2,w3;
adder_full_mul G0(.a(a[0]),  .b(b[0]),  .cin(cin),  .sum(sum[0]),  .carry(w1));
adder_full_mul G1(.a(a[1]),  .b(b[1]),  .cin(w1),   .sum(sum[1]),  .carry(w2));
adder_full_mul G2(.a(a[2]),  .b(b[2]),  .cin(w2),   .sum(sum[2]),  .carry(w3));
adder_full_mul G3(.a(a[3]),  .b(b[3]),  .cin(w3),   .sum(sum[3]),  .carry(carry));
endmodule

module adder8_mul(
    input [7:0] A,
    input [7:0] B,
   input Cin,
   output [7:0] Sum,
   output Cout
    );
adder4_mul F0( .a(A[3:0]),  .b(B[3:0]),  .cin(Cin),      .sum(Sum[3:0]),  .carry(ripple));
adder4_mul F1( .a(A[7:4]),  .b(B[7:4]),  .cin(ripple),   .sum(Sum[7:4]),  .carry(Cout));
endmodule

module adder9_mul(
    input [8:0] A,
    input [8:0] B,
    input Cin,
    output [8:0] Sum,
    output Cout
    );
adder8_mul adder0(.A(A[7:0]),  .B(B[7:0]), .Cin(Cin),  .Sum(Sum[7:0]),  .Cout(ripple));
adder_full_mul fa0(.a(A[8]),  .b(B[8]),  .cin(ripple),  .sum(Sum[8]),  .carry(Cout));
endmodule

module mux_mul(
   input fi,
   input si,
   input SL,
   output Y
   );
wire invSL,and1,and2,or1;
and(and1,SL,si);
not(invSL,SL);
and(and2,invSL,fi);
or(Y,and1,and2);
endmodule

module mux_multi_mul(
   input [31:0]A,
   input [31:0]B,
   input SL,
   output [31:0]O
   );
mux_mul M01 (.fi(A[31]),.si(B[31]),.SL(SL),.Y(O[31]));
mux_mul M02 (.fi(A[30]),.si(B[30]),.SL(SL),.Y(O[30]));
mux_mul M03 (.fi(A[29]),.si(B[29]),.SL(SL),.Y(O[29]));
mux_mul M04 (.fi(A[28]),.si(B[28]),.SL(SL),.Y(O[28]));
mux_mul M05 (.fi(A[27]),.si(B[27]),.SL(SL),.Y(O[27]));
mux_mul M06 (.fi(A[26]),.si(B[26]),.SL(SL),.Y(O[26]));
mux_mul M07 (.fi(A[25]),.si(B[25]),.SL(SL),.Y(O[25]));
mux_mul M08 (.fi(A[24]),.si(B[24]),.SL(SL),.Y(O[24]));
mux_mul M09 (.fi(A[23]),.si(B[23]),.SL(SL),.Y(O[23]));
mux_mul M10 (.fi(A[22]),.si(B[22]),.SL(SL),.Y(O[22]));
mux_mul M11 (.fi(A[21]),.si(B[21]),.SL(SL),.Y(O[21]));
mux_mul M12 (.fi(A[20]),.si(B[20]),.SL(SL),.Y(O[20]));
mux_mul M13 (.fi(A[19]),.si(B[19]),.SL(SL),.Y(O[19]));
mux_mul M14 (.fi(A[18]),.si(B[18]),.SL(SL),.Y(O[18]));
mux_mul M15 (.fi(A[17]),.si(B[17]),.SL(SL),.Y(O[17]));
mux_mul M16 (.fi(A[16]),.si(B[16]),.SL(SL),.Y(O[16]));
mux_mul M17 (.fi(A[15]),.si(B[15]),.SL(SL),.Y(O[15]));
mux_mul M18 (.fi(A[14]),.si(B[14]),.SL(SL),.Y(O[14]));
mux_mul M19 (.fi(A[13]),.si(B[13]),.SL(SL),.Y(O[13]));
mux_mul M20 (.fi(A[12]),.si(B[12]),.SL(SL),.Y(O[12]));
mux_mul M21 (.fi(A[11]),.si(B[11]),.SL(SL),.Y(O[11]));
mux_mul M22 (.fi(A[10]),.si(B[10]),.SL(SL),.Y(O[10]));
mux_mul M23 (.fi(A[9]) ,.si(B[9]) ,.SL(SL),.Y(O[9]) );
mux_mul M24 (.fi(A[8]) ,.si(B[8]) ,.SL(SL),.Y(O[8]) );
mux_mul M25 (.fi(A[7]) ,.si(B[7]) ,.SL(SL),.Y(O[7]) );
mux_mul M26 (.fi(A[6]) ,.si(B[6]) ,.SL(SL),.Y(O[6]) );
mux_mul M27 (.fi(A[5]) ,.si(B[5]) ,.SL(SL),.Y(O[5]) );
mux_mul M28 (.fi(A[4]) ,.si(B[4]) ,.SL(SL),.Y(O[4]) );
mux_mul M29 (.fi(A[3]) ,.si(B[3]) ,.SL(SL),.Y(O[3]) );
mux_mul M30 (.fi(A[2]) ,.si(B[2]) ,.SL(SL),.Y(O[2]) );
mux_mul M31 (.fi(A[1]) ,.si(B[1]) ,.SL(SL),.Y(O[1]) );
mux_mul M32 (.fi(A[0]) ,.si(B[0]) ,.SL(SL),.Y(O[0]) );
   
endmodule
