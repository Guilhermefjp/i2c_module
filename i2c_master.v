module i2c_master(
						input clk,
						input rst,
						input [6:0] addr_top,		//addr size : 7
						input [7:0] data_in_top,	//data size : 8
						input enable,
						input rd_wr,	//top module signal
						
						output reg[7:0] data_out,
						output ready,
						
						inout sda,
						inout scl
						);

	parameter idle_state = 0;
	parameter start_state = 1;
	parameter address_state = 2;
	parameter read_ack_state = 3;
	parameter write_data_state = 4;
	parameter write_ack_state = 5;
	parameter read_data_state = 6;
	parameter read_ack_2_state = 7;
	parameter stop_state = 8;
	
	parameter div_cont = 4;

	reg [7:0] state;
	reg [7:0] temp_addr;
	reg [7:0] temp_data;
	reg [7:0] counter1 = 8'd0;		// i2c clock
	reg [7:0] counter2 = 8'd0;
	reg 		 wr_enb;
	reg	    sda_out;
	reg		 i2c_clk;
	reg       i2c_scl_enable = 1'b0;
	
	
	// logic clock generation
	always @(posedge clk)begin
		if(counter1 == (div_cont/2) - 1)begin	//counter1 == 1
			i2c_clk = ~i2c_clk;
			counter1 <= 8'd0;
		end else	
			counter1 <= counter1 + 8'd1;
	end

	assign scl = (i2c_scl_enable == 1'b0) ? 1'b1 : i2c_clk;	//enable de scl 
	
	
	// logic i2c_scl_enable	
	always @(posedge i2c_clk, posedge rst)begin
		if(rst == 1'b1)
			i2c_scl_enable <= 1'b0;
		else	
			if(state == idle_state || state == start_state || state == stop_state)
				i2c_scl_enable <= 1'b0;
			else 
				i2c_scl_enable <= 1'b1;		//state == read_state
	end
	
	// state machine logic
	always @(posedge i2c_clk, posedge rst)begin
		case(state)
			idle_state: begin
								if(enable)begin							
									state <= start_state;
									
									temp_addr <= {addr_top,rd_wr};
									temp_data <= data_in_top;
									
								end else 
									state <= idle_state;
							end
							
			start_state: begin
								counter2 <= 8'd7;
								state <= address_state;
								
							 end
							 
			 address_state : begin
									if(counter2 == 0)begin
										state <= read_ack_state;
									
									end else 
											counter2 <= counter2 - 8'd1;
								  end
								  
			 read_ack_state : begin
										if(sda == 1'b0)
											counter2 <= 8'd7; 
										if(temp_addr[0] == 1'b0)
											state <= write_data_state;
										else if(temp_addr[0] == 1'b1)
												state <= read_data_state;
											  else
												state <= stop_state;
									end
			 write_data_state : begin
										if(counter2 == 8'd0)
											state <= read_ack_2_state;
										else 
											counter2 <= counter2 - 8'd1;
									  end	
			 read_ack_2_state : begin
										if(sda == 1'b0 && enable == 1'b1)
											state <= idle_state;
										else	state <= stop_state;																					
									  end
			 read_data_state : begin
										data_out[counter2] <= sda;
										
										if(counter2 == 0)
											state <= write_ack_state;
										else	
											counter2 <= counter2 - 8'd1;
									 end	
			 write_ack_state : begin
										state <= stop_state;
									 end
			 stop_state : begin
								state <= idle_state;
							  end

		endcase
	end
	
	
	// logic for genarating the output
	always @(posedge i2c_clk, posedge rst)begin
		if(rst == 1'b1)begin
			wr_enb <= 1'b1;
			sda_out <= 1'b1;
		end else begin
						case(state)
							start_state: begin
												wr_enb <= 1'b1;
												sda_out <= 1'b0;
											 end
							address_state : begin
													sda_out <= temp_addr[counter2];
												 end
							read_ack_state : begin
													wr_enb <= 1'b0;
												  end	
							write_data_state : begin
														wr_enb <= 1'b1;
														sda_out <= temp_data[counter2];
													 end
							read_data_state : begin
														wr_enb <= 1'b0;														
													end
							write_ack_state: begin
													wr_enb <= 1'b0;
													sda_out <= 1'b0;
												  end	
							stop_state : begin
												wr_enb <= 1'b1;
												sda_out <= 1'b1;
											 end
						endcase
					end							
	end
	
	// logic for sda
	assign sda = (wr_enb == 1'b1) ? sda_out : 1'bz;		// deixa sda hZ qndo na leitura e habilita na escrita
	 
	//logic for ready signal
	assign ready = ((rst == 1'b0) && (state == idle_state)) ? 1'b1 : 1'b0;
	
endmodule
