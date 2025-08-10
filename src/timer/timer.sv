`timescale 1ns/100ps

module Timer #(

parameter DATA_WIDTH = 32,
parameter ADDR_WIDTH = 32

)
(
input logic 					clk,
input logic 					rst,
input logic                  	rd_en,
input logic                  	wr_en,
input logic [ADDR_WIDTH-1:0] 	address,
input logic [DATA_WIDTH-1:0] 	wr_data,
output logic [DATA_WIDTH-1:0] 	rd_data,
output logic                  	ready,
output logic                  	error,
output logic                  	pwm,
output logic 					wd_rst
);




///////////// Internal registers ////////////////
logic [7:0]  		   timer_ctrl;     // 0x00
logic [DATA_WIDTH-1:0] timer_load;     // 0x04 
logic [DATA_WIDTH-1:0] wd_max;		   // 0x08 
logic [DATA_WIDTH-1:0] pwm_thres;      // 0x0C
logic [DATA_WIDTH-1:0] timer_count;    // 0x10 (Read only)
logic 				   timer_status;   // 0x14 (Read only)



//////////// Internal logic signals //////////////
logic load;
logic [DATA_WIDTH-1:0] wd_counter;
logic [2:0] pwm_counter;






///////////////// Write logic ////////////////////
always_ff @(posedge clk or negedge rst) begin 
	if(~rst) begin
		timer_ctrl <= {8{1'b0}};
		timer_load <= {DATA_WIDTH{1'b0}};
		wd_max <= 32'd10;
		pwm_thres <= {DATA_WIDTH{1'b0}};
		error <= 1'b0;
	end else begin
		if (wr_en && !rd_en) begin
			unique case (address)
				{2'b01,30'h00}: begin 
					timer_ctrl <= wr_data[7:0];
					error <= 1'b0;
				end
		        {2'b01,30'h04}: begin
		        	timer_load <= wr_data;
		        	error <= 1'b0;
		        end
		        {2'b01,30'h08}: begin
		        	wd_max <= wr_data;
		        	error <= 1'b0;
		        end
		        {2'b01,30'h0C}: begin
		        	pwm_thres <= wr_data;
		        	error <= 1'b0;
		        end
		        default: begin
		        	error <= 1'b1;
		        end 
			endcase
		end
	end
end






///////////////// Read logic ////////////////////
always_comb begin
	if (rd_en && !wr_en) begin
	    unique case (address)
	        {2'b01,30'h00}: begin
	        	rd_data = {24'b0,timer_ctrl};
	        	ready = 1'b1;
	     	end
	        {2'b01,30'h04}: begin
	        	rd_data = timer_load;
	        	ready = 1'b1;
	        end
	        {2'b01,30'h08}: begin
	        	rd_data = wd_max;
	        	ready = 1'b1;
	        end
	        {2'b01,30'h0C}: begin
	        	rd_data = pwm_thres;
	        	ready = 1'b1;
	        end
	        {2'b01,30'h10}: begin
	        	rd_data = timer_count;
	        	ready = 1'b1;
	        end
	        {2'b01,30'h14}: begin
	        	if (timer_status) begin
	        		rd_data = {31'b0,timer_status};
	        		ready = 1'b1;
	        	end else begin
	        		rd_data = {31'b0,timer_status};
	        		ready = 1'b0;
	        	end
	        end
	        default: begin
	        	rd_data = {DATA_WIDTH{1'b0}};
	        	ready = 1'b1;
	        end
	    endcase
	end else begin
		rd_data = {DATA_WIDTH{1'b0}};
	    ready = 1'b1;
	end
end






///////////////// Timer logic ////////////////////

//Load logic
always_ff @(posedge clk or negedge rst) begin 
	if(~rst) begin
		load <= 0;
	end else begin
		if (address == {2'b01,30'h04} && timer_ctrl[0]) begin
			load <= 1'b1;
		end else  begin
			load <= 1'b0;
		end 
	end
end

//Timer count and timer status logic
always_ff @(posedge clk or negedge rst) begin
	if(~rst) begin
		timer_status <= 1'b0;
		timer_count <= {DATA_WIDTH{1'b0}};
	end else begin 
		if (timer_ctrl[0]) begin
			if (load == 1'b1) begin
				timer_count <= timer_load;
			end else begin
				if (timer_count > 1) begin
					timer_count <= timer_count - 1;
					timer_status <= 1'b0;
				end else if (timer_count == 1) begin
					timer_count <= timer_count - 1;
					timer_status <= 1'b1;
				end else begin
					timer_status <= 1'b1;
				end
			end
		end else begin
			timer_status <= 1'b0;
			timer_count <= {DATA_WIDTH{1'b0}};
		end
	end
end







///////////////// Watchdog logic ////////////////////


always_ff @(posedge clk or negedge rst) begin 
	if(~rst) begin
		wd_rst <= 1'b0;
		wd_counter <= {DATA_WIDTH{1'b0}};
	end else begin
		if (timer_ctrl[1]) begin
			if (wd_counter != wd_max) begin
				wd_counter <= wd_counter + 1;	
			end else begin
				wd_rst <= 1'b1;
			end
		end else begin
			wd_rst <= 1'b0;
			wd_counter <= {DATA_WIDTH{1'b0}};
		end
	end
end







///////////////// PWM logic ////////////////////


always_ff @(posedge clk or negedge rst) begin 
	if(~rst) begin
		pwm <= 1'b0;
		pwm_counter <= 3'b000;
	end else begin
		if (timer_ctrl[2]) begin
			pwm_counter <= pwm_counter + 1;
			if (pwm_counter < pwm_thres[2:0] ) begin
				pwm <= 1'b0;
			end else begin
				pwm <= 1;
			end
		end else begin
			pwm_counter <= 3'b000;
			pwm <= 1'b0;
		end
	end
end




endmodule
