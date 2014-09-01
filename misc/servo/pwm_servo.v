/* Servo driver for model airplane servos
 * registers: (Little Endian)
 * 0 period 
 * 1 ontime
 * 2 config
 * config[0] = Enable (active high)
 */
module pwm_servo(clk, out, baseaddr, data, addr, w);
   input         clk;
   output        out;
   input [15:0]  baseaddr;
   input [31:0]  data;
   input [15:0]  addr;
   input         w;
   reg [31:0]    period, ontime, acctime;
   reg           enable, out_reg;
   assign        out = out_reg & enable;
   always @(posedge clk)
     begin
        if(w == 1'b1 && addr[1:0] == 0 && addr[15:2] == baseaddr[15:2])
          begin 
             period <= data;
             acctime <= 0;
             out_reg <= 1'b1;
          end
        else if(w == 1'b1 && addr[1:0] == 1 && addr[15:2] == baseaddr[15:2])
          begin
             ontime <= data;
             acctime <= 0;
             out_reg <= 1'b1;
          end
        else if(w == 1'b1 && addr[1:0] == 2 && addr[15:2] == baseaddr[15:2])
          begin
             enable <= data[0];
             acctime <= 0;
             out_reg <= 1'b1;
          end
        else if(acctime == period)
          begin
             acctime <= 0;
             out_reg <= 1'b1;
          end
        else if(acctime == ontime)
          begin
             out_reg <= 1'b0;
             acctime <= acctime + 1;
          end
        else
          begin
             acctime <= acctime + 1;
          end
     end // always @ (posedge clk)
endmodule // phase_acc_14_48

module pwm_servo_x8(clk, out, data, addr, w);
   input         clk;
   output [7:0]  out;
   input [31:0]  data;
   input [15:0]  addr;
   input         w;
   pwm_servo pwm_servo_0(clk, out[0], 16'h100, data, addr, w);
   pwm_servo pwm_servo_1(clk, out[1], 16'h104, data, addr, w);
   pwm_servo pwm_servo_2(clk, out[2], 16'h108, data, addr, w);
   pwm_servo pwm_servo_3(clk, out[3], 16'h112, data, addr, w);
   pwm_servo pwm_servo_4(clk, out[4], 16'h116, data, addr, w);
   pwm_servo pwm_servo_5(clk, out[5], 16'h120, data, addr, w);
   pwm_servo pwm_servo_6(clk, out[6], 16'h124, data, addr, w);
   pwm_servo pwm_servo_7(clk, out[7], 16'h128, data, addr, w);
endmodule // pwm_servo
