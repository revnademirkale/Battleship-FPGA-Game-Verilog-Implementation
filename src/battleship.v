// DO NOT CHANGE THE NAME OR THE SIGNALS OF THIS MODULE





module battleship (
  input            clk,   
  input            rst,   
  input            start, 
  input      [1:0] X,     
  input      [1:0] Y,     
  input            pAb,   
  input            pBb,   
  output reg [7:0] disp0, 
  output reg [7:0] disp1, 
  output reg [7:0] disp2, 
  output reg [7:0] disp3, 
  output reg [7:0] led    
);


parameter IDLE       = 4'd0;
parameter SHOW_A     = 4'd1;  
parameter A_IN    = 4'd2;
parameter ERROR_A    = 4'd3;
parameter SHOW_B     = 4'd4;
parameter B_IN    = 4'd5;  
parameter ERROR_B    = 4'd6;
parameter SHOW_SCORE = 4'd7;
parameter A_SHOOT    = 4'd8;
parameter B_SHOOT    = 4'd9;
parameter A_SINK     = 4'd10;
parameter B_SINK     = 4'd11;
parameter A_WIN      = 4'd12;
parameter B_WIN      = 4'd13;


parameter [25:0] TIMER_LIMIT = 26'd3;


reg [3:0]  internalCondition;        // was 'current_state'
reg [25:0] countDown;                // was 'timer'
reg [2:0]  shortWait;                // was 'wait_cycles'
reg [15:0] boardMatrixA, boardMatrixB;   // was 'boardA', 'boardB'
reg [2:0]  scoreCountA, scoreCountB;     // was 'scoreA', 'scoreB'
reg [2:0]  shipCounterA, shipCounterB;   // was 'placed_inputs_A', 'placed_inputs_B'
reg  [2:0]      blinkToggle;                  // was 'changing_variable'
reg        aGotPoint;                    // was 'A_made_a_score'
reg        bGotPoint;                    // was 'B_made_a_score'


always @(posedge clk) begin
  if (rst) begin
    // Synchronous reset
    internalCondition <= IDLE;
    countDown         <= 0;
    shortWait         <= 0;

    boardMatrixA      <= 16'b0;
    boardMatrixB      <= 16'b0;
    scoreCountA       <= 0;
    scoreCountB       <= 0;
    shipCounterA      <= 0;
    shipCounterB      <= 0;
    aGotPoint         <= 0;
    bGotPoint         <= 0;
    blinkToggle       <= 0;
    
  end else begin
    // 1) Decrement timer if > 0
    if (countDown > 0)
      countDown <= countDown - 1;

    

    // 2) State Machine
    case (internalCondition)

      
      IDLE: begin
        // If we detect start => go to SHOW_A
        if (start)
          internalCondition <= SHOW_A;
      end

      
      SHOW_A: begin
        if (shortWait < 3) begin
          shortWait <= shortWait + 1;
        end else begin
          shortWait <= 0;
          internalCondition <= A_IN;
        end
      end

      
      A_IN: begin
        if (pAb) begin
          // Check if location occupied => goto error
          if (boardMatrixA[X*4 + Y]) begin
            internalCondition <= ERROR_A;
            countDown         <= TIMER_LIMIT; // 1 second in error
          end else begin
            // place ship
            boardMatrixA[X*4 + Y] <= 1'b1;
            shipCounterA         <= shipCounterA + 1;
            // if 4 inputs => show B
            if (shipCounterA == 3)
              internalCondition <= SHOW_B;
          end
        end
      end

      
      ERROR_A: begin
        if (countDown == 0) begin
          internalCondition <= A_IN;
        end
      end

      
      SHOW_B: begin
        if (shortWait < 3) begin
          shortWait <= shortWait + 1;
        end else begin
          shortWait <= 0;
          internalCondition <= B_IN;
        end
      end

      
      B_IN: begin
        if (pBb) begin
          if (boardMatrixB[X*4 + Y]) begin
            internalCondition <= ERROR_B;
            countDown         <= TIMER_LIMIT;
          end else begin
            boardMatrixB[X*4 + Y] <= 1'b1;
            shipCounterB          <= shipCounterB + 1;
            if (shipCounterB == 3)
              internalCondition <= SHOW_SCORE;
          end
        end
      end

      
      ERROR_B: begin
        if (countDown == 0) begin
          internalCondition <= B_IN;
        end
      end

      
      SHOW_SCORE: begin
        if (shortWait < 3) begin
          shortWait <= shortWait + 1;
        end else begin
          shortWait <= 0;
          internalCondition <= A_SHOOT;
        end
      end

      A_SHOOT: begin
        // If pAb is pressed => check if B has a ship there
        if (pAb) begin
          if (boardMatrixB[X*4 + Y]) begin
            boardMatrixB[X*4 + Y] <= 1'b0;
            scoreCountA           <= scoreCountA + 1;
            aGotPoint             <= 1;
          end else begin
            aGotPoint             <= 0;
          end
          internalCondition <= A_SINK;
        end
      end

      A_SINK: begin
        // If A reached 4 => A_WIN
        if (scoreCountA == 4) begin
          internalCondition <= A_WIN;
          blinkToggle <= 0;

        end else begin
          if (shortWait < 3) begin
            internalCondition <= A_SINK;
            shortWait <= shortWait + 1;
          end else begin
            shortWait <= 0;
            internalCondition <= B_SHOOT;
          end
        end
      end

      
      B_SHOOT: begin
        // If pBb pressed => check if A had a ship
        if (pBb) begin
          if (boardMatrixA[X*4 + Y]) begin
            boardMatrixA[X*4 + Y] <= 1'b0;
            scoreCountB           <= scoreCountB + 1;
            bGotPoint             <= 1;
          end else begin
            bGotPoint             <= 0;
          end
          internalCondition <= B_SINK;
        end            
      end

      
      B_SINK: begin
        if (scoreCountB == 4) begin
          internalCondition <= B_WIN;
          blinkToggle <= 0;
        end else begin
          if (shortWait < 3) begin
            internalCondition <= B_SINK;
            shortWait <= shortWait + 1;

          end else begin
            shortWait <= 0;
            internalCondition <= A_SHOOT;
          end
        end
      end

      
      A_WIN: begin
        // Just toggle blinkToggle continuously
        if (blinkToggle == 0) begin
          blinkToggle <= 1;
        end
        else if(blinkToggle == 1) begin
          blinkToggle <= 2;
        end
        else if(blinkToggle == 2) begin
          blinkToggle <= 3;
        end
        else if(blinkToggle == 3) begin
          blinkToggle <= 4;
        end
        else if(blinkToggle == 4) begin
          blinkToggle <= 5;
        end
        else if(blinkToggle == 5) begin
          blinkToggle <= 6;
        end
        else if(blinkToggle == 6) begin
          blinkToggle <= 7;
        end
        else if(blinkToggle == 7) begin
          blinkToggle <= 0;
        end
      end

      
      B_WIN: begin
        if (blinkToggle == 0) begin
          blinkToggle <= 1;
        end
        else if(blinkToggle == 1) begin
          blinkToggle <= 2;
        end
        else if(blinkToggle == 2) begin
          blinkToggle <= 3;
        end
        else if(blinkToggle == 3) begin
          blinkToggle <= 4;
        end
        else if(blinkToggle == 4) begin
          blinkToggle <= 5;
        end
        else if(blinkToggle == 5) begin
          blinkToggle <= 6;
        end
        else if(blinkToggle == 6) begin
          blinkToggle <= 7;
        end
        else if(blinkToggle == 7) begin
          blinkToggle <= 0;
        end
      end

      default: begin
        internalCondition <= IDLE;
      end
    endcase
  end // end else not rst
end // end always @(posedge clk)



always @(*) begin
  // Default: turn everything off
  disp0 = 8'b00000000;  // was DIS_BLK
  disp1 = 8'b00000000;  // was DIS_BLK
  disp2 = 8'b00000000;  // was DIS_BLK
  disp3 = 8'b00000000;  // was DIS_BLK
  led   = 8'b00000000;

  case (internalCondition)

    
    IDLE: begin
      disp3 = 8'b00000110; // I
      disp2 = 8'b01011110; // D
      disp1 = 8'b00111000; // L
      disp0 = 8'b01111001; // E
      led   = 8'b10011001; // bits 7,4,3,0
    end

    
    SHOW_A: begin
      disp3 = 8'b01110111; // A
      disp2 = 8'b00000000;
      disp1 = 8'b00000000;
      disp0 = 8'b00000000;
      led   = 8'b00000000;
    end

    
    A_IN: begin
      led[7]   = 1'b1; 
      led[6]   = 1'b0;
      led[5:4] = shipCounterA[1:0];
      led[3:0] = 4'b0000;

      disp3 = 8'b00000000;
      disp2 = 8'b00000000;

      if(X == 0 && Y == 0)begin
        disp1 = 8'b00111111; // 0
        disp0 = 8'b00111111; // 0
      end
      else if(X == 0 && Y == 1)begin
        disp1 = 8'b00111111; // 0
        disp0 = 8'b00110000; // 1
      end
      else if(X == 0 && Y == 2)begin
        disp1 = 8'b00111111; // 0
        disp0 = 8'b01011011; // 2
      end
      else if(X == 0 && Y == 3)begin
        disp1 = 8'b00111111; // 0
        disp0 = 8'b01001111; // 3
      end
      else if(X == 1 && Y == 0)begin
        disp1 = 8'b00110000; // 1
        disp0 = 8'b00111111; // 0
      end
      else if(X == 1 && Y == 1)begin
        disp1 = 8'b00110000; // 1
        disp0 = 8'b00110000; // 1
      end
      else if(X == 1 && Y == 2)begin
        disp1 = 8'b00110000; // 1
        disp0 = 8'b01011011; // 2
      end
      else if(X == 1 && Y == 3)begin
        disp1 = 8'b00110000; // 1
        disp0 = 8'b01001111; // 3
      end
      else if(X == 2 && Y == 0)begin
        disp1 = 8'b01011011; // 2
        disp0 = 8'b00111111; // 0
      end
      else if(X == 2 && Y == 1)begin
        disp1 = 8'b01011011; // 2
        disp0 = 8'b00110000; // 1
      end
      else if(X == 2 && Y == 2)begin
        disp1 = 8'b01011011; // 2
        disp0 = 8'b01011011; // 2
      end
      else if(X == 2 && Y == 3)begin
        disp1 = 8'b01011011; // 2
        disp0 = 8'b01001111; // 3
      end
      else if(X == 3 && Y == 0)begin
        disp1 = 8'b01001111; // 3
        disp0 = 8'b00111111; // 0
      end
      else if(X == 3 && Y == 1)begin
        disp1 = 8'b01001111; // 3
        disp0 = 8'b00110000; // 1
      end
      else if(X == 3 && Y == 2)begin
        disp1 = 8'b01001111; // 3
        disp0 = 8'b01011011; // 2
      end
      else if(X == 3 && Y == 3)begin
        disp1 = 8'b01001111; // 3
        disp0 = 8'b01001111; // 3
      end
    end

    
    ERROR_A: begin
      disp3 = 8'b01111001; // E
      disp2 = 8'b01010000; // R
      disp1 = 8'b01010000; // R
      disp0 = 8'b00111111; // O
      led   = 8'b10011001; 
    end

    
    SHOW_B: begin
      disp3 = 8'b01111100; // B
      disp2 = 8'b00000000;
      disp1 = 8'b00000000;
      disp0 = 8'b00000000;
      led   = 8'b10011001;
    end

    
    B_IN: begin
      led[0]   = 1'b1; 
      led[3:2] = shipCounterB[1:0]; 
      led[7:4] = 4'b0000;
      led[1]   = 1'b0;

      disp3 = 8'b00000000;
      disp2 = 8'b00000000;

      if(X == 0 && Y == 0)begin
        disp1 = 8'b00111111; //0
        disp0 = 8'b00111111; //0
      end
      else if(X == 0 && Y == 1)begin
        disp1 = 8'b00111111; //0
        disp0 = 8'b00110000; //1
      end
      else if(X == 0 && Y == 2)begin
        disp1 = 8'b00111111; //0
        disp0 = 8'b01011011; //2
      end
      else if(X == 0 && Y == 3)begin
        disp1 = 8'b00111111; //0
        disp0 = 8'b01001111; //3
      end
      else if(X == 1 && Y == 0)begin
        disp1 = 8'b00110000; //1
        disp0 = 8'b00111111; //0
      end
      else if(X == 1 && Y == 1)begin
        disp1 = 8'b00110000; //1
        disp0 = 8'b00110000; //1
      end
      else if(X == 1 && Y == 2)begin
        disp1 = 8'b00110000; //1
        disp0 = 8'b01011011; //2
      end
      else if(X == 1 && Y == 3)begin
        disp1 = 8'b00110000; //1
        disp0 = 8'b01001111; //3
      end
      else if(X == 2 && Y == 0)begin
        disp1 = 8'b01011011; //2
        disp0 = 8'b00111111; //0
      end
      else if(X == 2 && Y == 1)begin
        disp1 = 8'b01011011; //2
        disp0 = 8'b00110000; //1
      end
      else if(X == 2 && Y == 2)begin
        disp1 = 8'b01011011; //2
        disp0 = 8'b01011011; //2
      end
      else if(X == 2 && Y == 3)begin
        disp1 = 8'b01011011; //2
        disp0 = 8'b01001111; //3
      end
      else if(X == 3 && Y == 0)begin
        disp1 = 8'b01001111; //3
        disp0 = 8'b00111111; //0
      end
      else if(X == 3 && Y == 1)begin
        disp1 = 8'b01001111; //3
        disp0 = 8'b00110000; //1
      end
      else if(X == 3 && Y == 2)begin
        disp1 = 8'b01001111; //3
        disp0 = 8'b01011011; //2
      end
      else if(X == 3 && Y == 3)begin
        disp1 = 8'b01001111; //3
        disp0 = 8'b01001111; //3
      end
    end

    
    ERROR_B: begin
      disp3 = 8'b01111001; // E
      disp2 = 8'b01010000; // R
      disp1 = 8'b01010000; // R
      disp0 = 8'b00111111; // O
      led   = 8'b10011001;
    end

    
    SHOW_SCORE: begin
      disp3 = 8'b00000000;
      disp2 = 8'b00111111; // 0
      disp1 = 8'b01000000; // dash
      disp0 = 8'b00111111; // 0
      led   = 8'b10011001;
    end

    
    A_SHOOT: begin
      disp3 = 8'b00000000;
      disp2 = 8'b00000000;
      led[1]   = 1'b0; 
      led[6]   = 1'b0; 
      led[0]   = 1'b0; 
      led[7]   = 1'b1; 
      led[5:4] = scoreCountA[1:0];
      led[3:2] = scoreCountB[1:0];

      if(X == 0 && Y == 0)begin
        disp1 = 8'b00111111; // 0
        disp0 = 8'b00111111; // 0
      end
      else if(X == 0 && Y == 1)begin
        disp1 = 8'b00111111; // 0
        disp0 = 8'b00110000; // 1
      end
      else if(X == 0 && Y == 2)begin
        disp1 = 8'b00111111; // 0
        disp0 = 8'b01011011; // 2
      end
      else if(X == 0 && Y == 3)begin
        disp1 = 8'b00111111; // 0
        disp0 = 8'b01001111; // 3
      end
      else if(X == 1 && Y == 0)begin
        disp1 = 8'b00110000; // 1
        disp0 = 8'b00111111; // 0
      end
      else if(X == 1 && Y == 1)begin
        disp1 = 8'b00110000; // 1
        disp0 = 8'b00110000; // 1
      end
      else if(X == 1 && Y == 2)begin
        disp1 = 8'b00110000; // 1
        disp0 = 8'b01011011; // 2
      end
      else if(X == 1 && Y == 3)begin
        disp1 = 8'b00110000; // 1
        disp0 = 8'b01001111; // 3
      end
      else if(X == 2 && Y == 0)begin
        disp1 = 8'b01011011; // 2
        disp0 = 8'b00111111; // 0
      end
      else if(X == 2 && Y == 1)begin
        disp1 = 8'b01011011; // 2
        disp0 = 8'b00110000; // 1
      end
      else if(X == 2 && Y == 2)begin
        disp1 = 8'b01011011; // 2
        disp0 = 8'b01011011; // 2
      end
      else if(X == 2 && Y == 3)begin
        disp1 = 8'b01011011; // 2
        disp0 = 8'b01001111; // 3
      end
      else if(X == 3 && Y == 0)begin
        disp1 = 8'b01001111; // 3
        disp0 = 8'b00111111; // 0
      end
      else if(X == 3 && Y == 1)begin
        disp1 = 8'b01001111; // 3
        disp0 = 8'b00110000; // 1
      end
      else if(X == 3 && Y == 2)begin
        disp1 = 8'b01001111; // 3
        disp0 = 8'b01011011; // 2
      end
      else if(X == 3 && Y == 3)begin
        disp1 = 8'b01001111; // 3
        disp0 = 8'b01001111; // 3
      end
    end

    
    A_SINK: begin
      disp3 = 8'b00000000;
      // A=8'b11110111, dash=8'b01000000
      disp2 = 8'b01110111; // A
      disp1 = 8'b01000000; // dash

      // If A got a point, all LEDs on for a moment, else all off
      if (aGotPoint)
        led = 8'b11111111;
      else
        led = 8'b00000000;

      if(scoreCountA == 0 && scoreCountB == 0)begin
        disp2 = 8'b00111111; //0
        disp0 = 8'b00111111; //0
      end
      else if(scoreCountA == 0 && scoreCountB == 1)begin
        disp2 = 8'b00111111; //0
        disp0 = 8'b00110000; //1
      end
      else if(scoreCountA == 0 && scoreCountB == 2)begin
        disp2 = 8'b00111111; //0
        disp0 = 8'b01011011; //2
      end
      else if(scoreCountA == 0 && scoreCountB == 3)begin
        disp2 = 8'b00111111; //0
        disp0 = 8'b01001111; //3
      end
      else if(scoreCountA == 1 && scoreCountB == 0)begin
        disp2 = 8'b00110000; //1
        disp0 = 8'b00111111; //0
      end
      else if(scoreCountA == 1 && scoreCountB == 1)begin
        disp2 = 8'b00110000; //1
        disp0 = 8'b00110000; //1
      end
      else if(scoreCountA == 1 && scoreCountB == 2)begin
        disp2 = 8'b00110000; //1
        disp0 = 8'b01011011; //2
      end
      else if(scoreCountA == 1 && scoreCountB == 3)begin
        disp2 = 8'b00110000; //1
        disp0 = 8'b01001111; //3
      end
      else if(scoreCountA == 2 && scoreCountB == 0)begin
        disp2 = 8'b01011011; //2
        disp0 = 8'b00111111; //0
      end
      else if(scoreCountA == 2 && scoreCountB == 1)begin
        disp2 = 8'b01011011; //2
        disp0 = 8'b00110000; //1
      end
      else if(scoreCountA == 2 && scoreCountB == 2)begin
        disp2 = 8'b01011011; //2
        disp0 = 8'b01011011; //2
      end
      else if(scoreCountA == 2 && scoreCountB == 3)begin
        disp2 = 8'b01011011; //2
        disp0 = 8'b01001111; //3
      end
      else if(scoreCountA == 3 && scoreCountB == 0)begin
        disp2 = 8'b01001111; //3
        disp0 = 8'b00111111; //0
      end
      else if(scoreCountA == 3 && scoreCountB == 1)begin
        disp2 = 8'b01001111; //3
        disp0 = 8'b00110000; //1
      end
      else if(scoreCountA == 3 && scoreCountB == 2)begin
        disp2 = 8'b01001111; //3
        disp0 = 8'b01011011; //2
      end
      else if(scoreCountA == 3 && scoreCountB == 3)begin
        disp2 = 8'b01001111; //3
        disp0 = 8'b01001111; //3
      end
    end

    
    B_SHOOT: begin
      disp3 = 8'b00000000;
      disp2 = 8'b00000000;
      led[1]   = 1'b0; 
      led[6]   = 1'b0; 
      led[7]   = 1'b0; 
      led[0]   = 1'b1; 
      led[5:4] = scoreCountA[1:0];
      led[3:2] = scoreCountB[1:0];

      if(X == 0 && Y == 0)begin
        disp1 = 8'b00111111; //0
        disp0 = 8'b00111111; //0
      end
      else if(X == 0 && Y == 1)begin
        disp1 = 8'b00111111; //0
        disp0 = 8'b00110000; //1
      end
      else if(X == 0 && Y == 2)begin
        disp1 = 8'b00111111; //0
        disp0 = 8'b01011011; //2
      end
      else if(X == 0 && Y == 3)begin
        disp1 = 8'b00111111; //0
        disp0 = 8'b01001111; //3
      end
      else if(X == 1 && Y == 0)begin
        disp1 = 8'b00110000; //1
        disp0 = 8'b00111111; //0
      end
      else if(X == 1 && Y == 1)begin
        disp1 = 8'b00110000; //1
        disp0 = 8'b00110000; //1
      end
      else if(X == 1 && Y == 2)begin
        disp1 = 8'b00110000; //1
        disp0 = 8'b01011011; //2
      end
      else if(X == 1 && Y == 3)begin
        disp1 = 8'b00110000; //1
        disp0 = 8'b01001111; //3
      end
      else if(X == 2 && Y == 0)begin
        disp1 = 8'b01011011; //2
        disp0 = 8'b00111111; //0
      end
      else if(X == 2 && Y == 1)begin
        disp1 = 8'b01011011; //2
        disp0 = 8'b00110000; //1
      end
      else if(X == 2 && Y == 2)begin
        disp1 = 8'b01011011; //2
        disp0 = 8'b01011011; //2
      end
      else if(X == 2 && Y == 3)begin
        disp1 = 8'b01011011; //2
        disp0 = 8'b01001111; //3
      end
      else if(X == 3 && Y == 0)begin
        disp1 = 8'b01001111; //3
        disp0 = 8'b00111111; //0
      end
      else if(X == 3 && Y == 1)begin
        disp1 = 8'b01001111; //3
        disp0 = 8'b00110000; //1
      end
      else if(X == 3 && Y == 2)begin
        disp1 = 8'b01001111; //3
        disp0 = 8'b01011011; //2
      end
      else if(X == 3 && Y == 3)begin
        disp1 = 8'b01001111; //3
        disp0 = 8'b01001111; //3
      end
    end

    
    B_SINK: begin
      // A's score => disp2, B's score => disp0
      // dash => disp1 = 8'b01000000
      disp2 = 8'b00000000;
      disp1 = 8'b01000000; // dash
      disp0 = 8'b00000000;

      if (bGotPoint)
        led = 8'b11111111;
      else
        led = 8'b00000000;

      if(scoreCountA == 0 && scoreCountB == 0)begin
        disp2 = 8'b00111111; //0
        disp0 = 8'b00111111; //0
      end
      else if(scoreCountA == 0 && scoreCountB == 1)begin
        disp2 = 8'b00111111; //0
        disp0 = 8'b00110000; //1
      end
      else if(scoreCountA == 0 && scoreCountB == 2)begin
        disp2 = 8'b00111111; //0
        disp0 = 8'b01011011; //2
      end
      else if(scoreCountA == 0 && scoreCountB == 3)begin
        disp2 = 8'b00111111; //0
        disp0 = 8'b01001111; //3
      end
      else if(scoreCountA == 1 && scoreCountB == 0)begin
        disp2 = 8'b00110000; //1
        disp0 = 8'b00111111; //0
      end
      else if(scoreCountA == 1 && scoreCountB == 1)begin
        disp2 = 8'b00110000; //1
        disp0 = 8'b00110000; //1
      end
      else if(scoreCountA == 1 && scoreCountB == 2)begin
        disp2 = 8'b00110000; //1
        disp0 = 8'b01011011; //2
      end
      else if(scoreCountA == 1 && scoreCountB == 3)begin
        disp2 = 8'b00110000; //1
        disp0 = 8'b01001111; //3
      end
      else if(scoreCountA == 2 && scoreCountB == 0)begin
        disp2 = 8'b01011011; //2
        disp0 = 8'b00111111; //0
      end
      else if(scoreCountA == 2 && scoreCountB == 1)begin
        disp2 = 8'b01011011; //2
        disp0 = 8'b00110000; //1
      end
      else if(scoreCountA == 2 && scoreCountB == 2)begin
        disp2 = 8'b01011011; //2
        disp0 = 8'b01011011; //2
      end
      else if(scoreCountA == 2 && scoreCountB == 3)begin
        disp2 = 8'b01011011; //2
        disp0 = 8'b01001111; //3
      end
      else if(scoreCountA == 3 && scoreCountB == 0)begin
        disp2 = 8'b01001111; //3
        disp0 = 8'b00111111; //0
      end
      else if(scoreCountA == 3 && scoreCountB == 1)begin
        disp2 = 8'b01001111; //3
        disp0 = 8'b00110000; //1
      end
      else if(scoreCountA == 3 && scoreCountB == 2)begin
        disp2 = 8'b01001111; //3
        disp0 = 8'b01011011; //2
      end
      else if(scoreCountA == 3 && scoreCountB == 3)begin
        disp2 = 8'b01001111; //3
        disp0 = 8'b01001111; //3
      end
    end

    
    A_WIN: begin
      // A=8'b11110111, 4=8'b01100110, dash=8'b01000000
      disp3 = 8'b01110111; // A
      disp2 = 8'b01100110; // 4
      disp1 = 8'b01000000; // dash

      // Show B's final score in disp0
      if(scoreCountB==0) begin
        disp0 = 8'b00111111; //0
      end
      if(scoreCountB==1) begin 
        disp0 = 8'b00110000; //1
      end
      if(scoreCountB==2) begin 
        disp0 = 8'b01011011; //2,
      end
      if(scoreCountB==3) begin
        disp0 = 8'b01001111; //3
      end

      // blinkToggle toggles the LED pattern
      if (blinkToggle == 0)begin
        led = 8'b10000000;
      end
      else if(blinkToggle == 1)begin
        led = 8'b01000000;
      end
      else if(blinkToggle == 2)begin
        led = 8'b00100000;
      end
      else if(blinkToggle == 3)begin
        led = 8'b00010000;
      end
      else if(blinkToggle == 4)begin
        led = 8'b00001000;
      end
      else if(blinkToggle == 5)begin
        led = 8'b00000100;
      end
      else if(blinkToggle == 6)begin
        led = 8'b00000010;
      end
      else if(blinkToggle == 7)begin
        led = 8'b00000001;
      end
        

        

    end

    B_WIN: begin
      // B=8'b11111100, 4=8'b01100110, dash=8'b01000000
      disp3 = 8'b01111100; // B
      disp1 = 8'b01000000; // dash
      disp0 = 8'b01100110; // 4

      // Show A's final score in disp2
      if(scoreCountA==0) begin
        disp2 = 8'b00111111; //0
      end
      if(scoreCountA==1) begin 
        disp2 = 8'b00110000; //1
      end
      if(scoreCountA==2) begin 
        disp2 = 8'b01011011; //2
      end
      if(scoreCountA==3) begin 
        disp2 = 8'b01001111; //3
      end

      if (blinkToggle == 0)begin
        led = 8'b10000000;
      end
      else if(blinkToggle == 1)begin
        led = 8'b01000000;
      end
      else if(blinkToggle == 2)begin
        led = 8'b00100000;
      end
      else if(blinkToggle == 3)begin
        led = 8'b00010000;
      end
      else if(blinkToggle == 4)begin
        led = 8'b00001000;
      end
      else if(blinkToggle == 5)begin
        led = 8'b00000100;
      end
      else if(blinkToggle == 6)begin
        led = 8'b00000010;
      end
      else if(blinkToggle == 7)begin
        led = 8'b00000001;
      end
    end

    default: begin
      // fallback
    end
  endcase
end

endmodule
