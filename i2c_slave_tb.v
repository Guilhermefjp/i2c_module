/**
Testing I2C Slace for reading/writing 8 bits of data only
*/

`timescale 1ns / 1ps

module i2c_slave_tb();

  reg clk,i2c_clk;
  
  wire SDA;
  wire SCL;
  
  pullup(SDA);
  pullup(SCL);
  
  reg [6:0] addressToSend 	= 7'b0101010;
  reg readWite 				= 1'b1; 		//write
  reg [7:0] dataToSend 		= 8'b0110_0111; //103 = 0x67
  
  integer ii=0;

  initial begin
		clk = 1'b1;	
		forever begin
			clk = #10 ~clk;
		end
	end
	
	initial begin
		i2c_clk = 0;
		forever begin
			i2c_clk = #1 ~i2c_clk;
		end
	end
	
  
  i2c_slave  UUT
	(  .clk(i2c_clk),
		.sda(SDA),
		.scl(SCL));

  initial 
    begin
      $display("Starting Testbench...");
      
		force SCL = 1'b1;
      force SDA = 1'b1;
      #110
      
      // Set SDA Low to start
      force SDA = 0;
		#10 force SCL = clk;
      // Write address
      for(ii=0; ii<7; ii=ii+1)
        begin
          $display("Address SDA %h to %h", SDA, addressToSend[ii]);
          #20 force SDA = addressToSend[ii];
        end
      
      // Are we wanting to read or write to/from the device?
      $display("Read/Write %h SDA: %h", readWite, SDA);
      #20 force SDA = readWite;
      
      // Next SDA will be driven by slave, so release it
      release SDA;
      
      $display("SDA: %h", SDA);
      #20; // Wait for ACK bit
      
      for(ii=0; ii<8; ii=ii+1)
        begin
          $display("Data SDA %h to %h", SDA, dataToSend[ii]);
          #20 force SDA = dataToSend[ii];
        end
      
      #20; // Wait for ACK bit
      
       // Next SDA will be driven by slave, so release it
      release SDA;
      
      // Force SDA high again, we are done
      #20 force SDA = 1;

      #1000;
      $finish();
    end
  
  initial 
  begin
    // Required to dump signals to EPWave
    $dumpfile("dump.vcd");
    $dumpvars(0);
  end
  
endmodule