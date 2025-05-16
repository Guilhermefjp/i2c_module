module i2c_slave(
						input clk,			// oversample clock 8-16x max scl 
					   inout sda,
						inout scl
					  );
					  
	parameter address_slave = 7'b0101010;
	
	parameter read_addr_state = 0;
	parameter send_ack_state = 1;
	parameter read_data_state = 2;
	parameter write_data_state = 3;
	parameter send_ack_2_state = 4;
	
	reg[7:0] addr;
	reg[7:0] counter;
	reg[7:0] state = 8'd0;
	reg[7:0] data_in = 8'd0;
	reg[7:0] data_out = 8'd0;
	reg 	   sda_out = 1'b0;
	reg 		sda_in = 1'b0;
	reg 		wr_enb = 1'b0;
	reg 		start = 1'b0;

	assign sda = (wr_enb == 1'b1) ? sda_out : 1'bz;		// sda output write enable and hight Z for read
	
	// Edge detection
//---------------------------------------------	
	reg scl_delay = 1'b0,sda_delay = 1'b0;
	wire scl_rising, scl_falling;
	wire sda_rising, sda_falling;
	
	always @(posedge clk) scl_delay <= scl;
	always @(posedge clk) sda_delay <= sda;

	assign scl_rising  = !scl_delay &  scl;
	assign scl_falling =  scl_delay & !scl;
	assign sda_rising  = !sda_delay &  sda;
	assign sda_falling =  sda_delay & !sda;

always @(posedge clk) begin
        // Detect start condition
        if (sda_falling && !start && scl) begin
            start <= 1'b1;
            counter <= 8'd7;
        end
        
        // Detect stop condition
        if (sda_rising && start && scl) begin
            state <= read_addr_state;
            start <= 1'b0;
            wr_enb <= 1'b0;
        end
        
        // State machine logic
        if (start && scl_rising) begin
            case (state)
                read_addr_state: begin
                    addr[counter] <= sda;
                    if (counter == 8'd0) begin
                        state <= send_ack_state;
                        wr_enb <= 1'b1;  // Prepare to send ACK
                        sda_out <= 1'b0; // ACK low
                    end else begin
                        counter <= counter - 8'd1;
                    end
                end
                
                send_ack_state: begin
                    if (addr[7:1] == address_slave) begin
                        counter <= 8'd7;
                        wr_enb <= (addr[0] == 1'b0) ? 1'b0 : 1'b1; // Read or write mode
                        state <= (addr[0] == 1'b0) ? read_data_state : write_data_state;
                    end else begin
                        // Address doesn't match, go back to idle
                        state <= read_addr_state;
                        wr_enb <= 1'b0;
                    end
                end
                
                read_data_state: begin
                    data_in[counter] <= sda;
                    if (counter == 8'd0) begin
                        state <= send_ack_2_state;
                        wr_enb <= 1'b1;  // Prepare to send ACK
                        sda_out <= 1'b0; // ACK low
                    end else begin
                        counter <= counter - 8'd1;
                    end
                end
                
                send_ack_2_state: begin
                    state <= read_addr_state;
                    wr_enb <= 1'b0;
                end
                
                write_data_state: begin
                    if (counter == 8'd0) begin
                        state <= read_addr_state;
                        wr_enb <= 1'b0;
                    end else begin
                        counter <= counter - 8'd1;
                        sda_out <= data_out[counter];
                    end
                end
            endcase
        end
    end	
endmodule

//---------------------------------------------	
/*
	always @(posedge clk)begin			
		if(sda_falling)begin
			if(start == 1'b0 && scl == 1'b1)begin			// if scl = 1 and sda transition -> start or stop
				start <= 1'b1;
				counter <= 8'd7;
			end
		end
	end
	
	always @(posedge clk)begin
		if(sda_rising)begin
			if(start == 1'b1 && scl == 1'b1)begin
				state <= read_addr_state;
				start <= 1'b0;
				wr_enb <= 1'b0;
			end
		end
	end
	
	//next state logic
	always @(posedge clk)begin
	if(scl_rising)begin
		if(start == 1'b1)begin
			case(state)
				read_addr_state: 	begin
											addr[counter] <= sda;
											if(counter == 8'd0)
												state <= send_ack_state;
											else	
												counter <= counter - 8'd1;
										end
				send_ack_state : 	begin
											if(addr[7:1] == address_slave) begin
												counter <= 8'd7;
												if(addr[0] == 1'b0)begin
													state <= read_data_state;
												end else 
													state <= write_data_state; 
											end
										end
				read_data_state :	begin
											data_in[counter] <= sda;
											if(counter == 8'd0)
												state <= send_ack_2_state;
											else 
												counter <= counter - 8'd1;
										end
				send_ack_2_state :	begin
												state <= read_addr_state;
											end
				write_data_state :	begin
												if(counter == 8'd0)
													state <= read_addr_state;
												else
													counter <=  counter - 8'd1;
											end

			endcase
		end
	end	
	end
	
	// logic output generation
	always @(posedge clk)begin
	if(scl_falling)begin
		case(state)
			read_addr_state : begin
										wr_enb <= 1'b0;
									end
			send_ack_state : 	begin
										sda_out <= 1'b0;
										wr_enb <= 1'b1;
									end
			read_data_state : begin
										wr_enb <= 1'b0;
									end
			send_ack_2_state : 	begin
											sda_out <= 1'b0;
											wr_enb <= 1'b1;
										end
			write_data_state : 	begin
											sda_out <= data_out[counter];
										end
		endcase	
	end
	end
*/