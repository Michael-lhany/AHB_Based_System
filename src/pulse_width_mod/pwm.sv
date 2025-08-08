module pwm 
(
input logic clk,
input logic rst,
generic_slave_if.slave_side intf,
output logic pwm
);



///////////// Internal registers ////////////////
logic [3:0] threshold;



///////////// Internal logic signals ////////////////
logic [3:0] counter, counter_next;
logic pwm_next;



///////////////// Write logic ////////////////////


always_ff @(posedge clk or negedge rst) begin 
  if(~rst) begin
    threshold <= 4'b1111;
    intf.ready <= 1'b1;
    intf.error <= 1'b0;
  end else begin
    if (intf.wr_en && !intf.rd_en && ( intf.address == {2'b10,30'h00} ) )begin
      threshold <= intf.wr_data[3:0];
    end
  end
end


///////////////// internal logic ////////////////////

always_comb begin
  counter_next = counter + 1;

  if (counter >= threshold) begin
    pwm_next = 1;
  end
  else begin
    pwm_next = 0;
  end
end

always_ff @(posedge clk or negedge rst) begin
  if (!rst) begin
    counter <= 0;
    pwm     <= 0;
  end
  else begin
    counter <= counter_next;
    pwm     <= pwm_next;
  end
end



endmodule