module arbiter
#(
parameter ADDR_WIDTH = 32,
parameter DATA_WIDTH = 32
)(


/////////////// MASTER 0 INTERFACE //////////////////


input  logic [ADDR_WIDTH-1:0] HADDR_M0,
input  logic                  HWRITE_M0,
input  logic [DATA_WIDTH-1:0] HWDATA_M0,
input  logic [1:0]            HTRANS_M0,
input  logic [2:0]            HSIZE_M0,
input  logic [3:0]            HPROT_M0,
input  logic [2:0]            HBURST_M0,
input  logic                  req0,

output logic [DATA_WIDTH-1:0] HRDATA_M0,
output logic                  HREADY_M0,
output logic                  HRESP_M0,


/////////////// MASTER 1 INTERFACE //////////////////


input  logic [ADDR_WIDTH-1:0] HADDR_M1,
input  logic                  HWRITE_M1,
input  logic [DATA_WIDTH-1:0] HWDATA_M1,
input  logic [1:0]            HTRANS_M1,
input  logic [2:0]            HSIZE_M1,
input  logic [3:0]            HPROT_M1,
input  logic [2:0]            HBURST_M1,
input  logic                  req1,

output logic [DATA_WIDTH-1:0] HRDATA_M1,
output logic                  HREADY_M1,
output logic                  HRESP_M1,


/////////////// OUTPUT TO SLAVES //////////////////


output logic [ADDR_WIDTH-1:0] HADDR_OUT,
output logic                  HWRITE_OUT,
output logic [DATA_WIDTH-1:0] HWDATA_OUT,
output logic [1:0]            HTRANS_OUT,
output logic [2:0]            HSIZE_OUT,
output logic [3:0]            HPROT_OUT,
output logic [2:0]            HBURST_OUT,
input  logic [DATA_WIDTH-1:0] HRDATA_IN,
input  logic                  HREADY_IN,
input  logic                  HRESP_IN
);




/////////////// ARBITER: Fixed Priority (Master0 > Master1) OR Round-Robin //////////////////


logic grant0, grant1;

always_comb begin
    grant0 = 0;
    grant1 = 0;

    if (req0) begin 
        grant0 = 1;
    end else if (req1) begin
        grant1 = 1;
    end
end


/////////////// OUTPUT TO SLAVES //////////////////


assign HADDR_OUT  = grant0 ? HADDR_M0  : HADDR_M1;
assign HWRITE_OUT = grant0 ? HWRITE_M0 : HWRITE_M1;
assign HWDATA_OUT = grant0 ? HWDATA_M0 : HWDATA_M1;
assign HTRANS_OUT = grant0 ? HTRANS_M0 : HTRANS_M1;
assign HSIZE_OUT  = grant0 ? HSIZE_M0  : HSIZE_M1;
assign HPROT_OUT  = grant0 ? HPROT_M0  : HPROT_M1;
assign HBURST_OUT = grant0 ? HBURST_M0 : HBURST_M1;

/////////////// RETURN SLAVE RESPONSES TO THE GRANTED MASTER ONLY //////////////////


assign HRDATA_M0   = grant0 ? HRDATA_IN   : '0;
assign HREADY_M0 = grant0 ? HREADY_IN    : 1'b0;
assign HRESP_M0    = grant0 ? HRESP_IN    : 1'b0;

assign HRDATA_M1   = grant1 ? HRDATA_IN   : '0;
assign HREADY_M1 = grant1 ? HREADY_IN    : 1'b0;
assign HRESP_M1    = grant1 ? HRESP_IN    : 1'b0;

endmodule