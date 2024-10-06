`timescale 1ns / 1ps

`include "ALU.v"

module ALU_tb;

  // Inputs
  reg [31:0] A;
  reg [31:0] B;
  reg [1:0] operation;

  // Outputs
  wire Exception;
  wire Overflow;
  wire Underflow;
  wire [31:0] Result;

  ALU simulator (
    .A(A), 
    .B(B), 
    .operation(operation), 
    .Exception(Exception), 
    .Overflow(Overflow), 
    .Underflow(Underflow), 
    .Result(Result)
  );

initial begin
    $dumpfile("ALU_tb.vcd");
    $dumpvars(0, ALU_tb);

    // Monitor tín hiệu
    $monitor("A = %h, B = %h, Exception = %b, Overflow = %b, Underflow = %b, Result = %h", A, B, Exception, Overflow, Underflow, Result);

    // Initialize Inputs
    A = 32'b01000001000111001100110011001101; //9.8
    B = 32'b01000000100010011001100110011010; //4.3
    operation = 3'b00; // Addition

    // Wait 100 ns for global reset to finish
    #100;
        
    A = 32'b01000001000111001100110011001101; //9.8
    B = 32'b01000000100010011001100110011010; //4.3
    operation = 3'b01; // Subtraction

    // Wait 100 ns for global reset to finish
    #100;
    
    A = 32'b01000001000111001100110011001101; //9.8
    B = 32'b01000000100010011001100110011010; //4.3
    operation = 3'b10; // Multiplication

    // Wait 100 ns for global reset to finish
    #100;
    
    A = 32'b01000001000111001100110011001101; //9.8
    B = 32'b01000000100010011001100110011010; //4.3
    operation = 3'b11; // Division

    // Wait 100 ns for global reset to finish
    #100;

end

endmodule