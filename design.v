`include "DEFINE.v"
module aluDesign#(parameter W = 8, N = 4) (clk,rst,CE,MODE,CIN,INP_VALID,CMD,OPA,OPB, ERR,OV,COUT,G,L,E, RES);
    input clk,rst,CE,MODE,CIN;
    input [1:0] INP_VALID;
    input [N-1:0] CMD;
    input [W-1:0] OPA,OPB;
    output reg ERR,OV,COUT,G,L,E;

    `ifdef MUL
        output reg [2*W-1:0] RES;
        reg [2*W-1:0] res_comb,res_mult;
    `else
        output reg[W:0] RES;
        reg [W:0] res_comb,res_mult;

    `endif

    parameter INV_INP = 2'b00, OPA_VALID = 2'b01, OPB_VALID = 2'b10, OPA_AND_OPB_VALID = 2'b11;

    parameter SHIFT_W = $clog2(W);

    reg [W-1:0] opa_r,opb_r;
    reg [N-1:0] cmd_r;
    reg [1:0] valid_r;
    reg mode_r,cin_r;
    reg cout_comb,ov_comb,g_comb,l_comb,e_comb,err_comb;


    always@(posedge clk,posedge rst) begin
        if(rst) begin
            opa_r <= 0;
            opb_r <= 0;
            cmd_r <= 0;
            valid_r <= 0;
            cin_r <= 0;
            mode_r <= 0;
        end
        else if(CE) begin
            opa_r <= OPA;
            opb_r <= OPB;
            cmd_r <= CMD;
            valid_r <= INP_VALID;
            cin_r <= CIN;
            mode_r <= MODE;
       end
    end



    always@(*) begin

        if(CE) begin
            res_comb = 0;
            err_comb = 0;
            cout_comb = 0;
            ov_comb = 0;
            g_comb = 0;
            l_comb = 0;
            e_comb = 0;
            res_mult = 0;
            if(mode_r == 1) begin
                case(valid_r)
                    INV_INP : begin
                        res_comb = 0;
                        err_comb = 1;
                    end
                    OPA_VALID : begin
                        case(cmd_r)
                            `INC_A : begin
                                res_comb = opa_r + 1;
                                cout_comb = res_comb[W];
                            end
                           `DEC_A : begin
                               res_comb = opa_r - 1;
                               ov_comb = res_comb[W];
                            end
                            default : err_comb = 1;
                        endcase
                    end
                    OPB_VALID : begin
                        case(cmd_r)
                            `INC_B : begin
                                res_comb = opb_r + 1;
                                cout_comb = res_comb[W];
                            end
                            `DEC_B : begin
                                res_comb = opb_r - 1;
                                ov_comb = res_comb[W];
                            end
                            default : err_comb = 1;
                        endcase
                    end
                    OPA_AND_OPB_VALID : begin
                        case(cmd_r)
                            `ADD : begin
                                res_comb = opa_r + opb_r;
                                cout_comb = res_comb[W];
                            end
                            `SUB : begin
                                res_comb = opa_r - opb_r;
                                ov_comb = res_comb[W];
                            end
                            `ADD_CIN : begin
                                res_comb = opa_r + opb_r + cin_r;
                                cout_comb = res_comb[W];
                            end
                            `SUB_CIN : begin
                                res_comb = opa_r - opb_r - cin_r;
                                ov_comb = res_comb[W];
                            end
                            `CMP : begin
                                g_comb  = (opa_r > opb_r) ? 1:0;
                                l_comb = (opa_r < opb_r) ? 1:0;
                                e_comb = (opa_r == opb_r) ? 1:0;
                            end
                            `MULT_INC : begin
                                res_comb = (opa_r + 1) * (opb_r + 1);
                            end
                            `MULT_SHIFT_A : begin
                                res_comb = (opa_r<<1) * (opb_r);
                            end
                            `S_ADD : begin
                                res_comb = $signed(opa_r) + $signed(opb_r);
                                ov_comb = (($signed(opa_r) > 0) && ($signed(opb_r) > 0) && ($signed(res_comb[W-1:0])<=0) || ($signed(opa_r) < 0) && ($signed(opb_r) < 0) && ($signed(res_comb[W-1:0]) >= 0));
                                g_comb  = ($signed(opa_r) > $signed(opb_r)) ? 1:0;
                                l_comb = ($signed(opa_r) < $signed(opb_r)) ? 1:0;
                                e_comb = ($signed(opa_r) == $signed(opb_r)) ? 1:0;

                            end
                            `S_SUB : begin
                                res_comb = $signed(opa_r) - $signed(opb_r);
                                ov_comb = (($signed(opa_r) > 0) && ($signed(opb_r) < 0) && ($signed(res_comb[W-1:0]) <= 0) || ($signed(opa_r) < 0) && ($signed(opb_r) > 0) && ($signed(res_comb[W-1:0]) >= 0));
                                g_comb  = ($signed(opa_r) > $signed(opb_r)) ? 1:0;
                                l_comb = ($signed(opa_r) < $signed(opb_r)) ? 1:0;
                                e_comb = ($signed(opa_r) == $signed(opb_r)) ? 1:0;

                            end
                            default : err_comb = 1;
                        endcase
                    end
                    default : err_comb = 1;
                endcase
            end
            else begin
                case(valid_r)
                    INV_INP : begin
                        res_comb = 0;
                        err_comb = 1;
                    end
                    OPA_VALID : begin
                        case(cmd_r)
                            `NOT_A : begin
                                res_comb = ~(opa_r);
                                res_comb[2*W-1 : 8] = 0;
                            end
                            `SHR1_A : begin
                                res_comb = opa_r >> 1;
                            end
                            `SHL1_A : begin
                                res_comb = opa_r << 1;
                            end
                            default : err_comb = 1;
                        endcase
                    end
                    OPB_VALID : begin
                        case(cmd_r)
                            `NOT_B : begin
                                res_comb = ~(opb_r);
                                res_comb[2*W-1 : 8] = 0;
                            end
                            `SHR1_B : begin
                                res_comb = opb_r >> 1;
                            end
                            `SHL1_B : begin
                                res_comb = opb_r << 1;
                            end
                            default : err_comb = 1;
                        endcase
                    end
                    OPA_AND_OPB_VALID : begin
                        case(cmd_r)
                            `AND : begin
                                res_comb = opa_r & opb_r;
                            end
                            `NAND : begin
                                res_comb = ~(opa_r & opb_r);
                                res_comb[2*W-1 : 8] = 0;
                            end
                            `OR : begin
                                res_comb = opa_r | opb_r;

                            end
                            `NOR : begin
                                res_comb = ~(opa_r | opb_r);
                                res_comb[2*W-1 : 8] = 0;

                            end
                            `XOR : begin
                                res_comb = opa_r ^ opb_r;
                            end
                            `XNOR : begin
                                res_comb = ~(opa_r ^ opb_r);
                                res_comb[2*W-1 : 8] = 0;

                            end
                            `ROL_A_B : begin
                                if( |(opb_r[(W-1) : (SHIFT_W+1)])) begin
                                    err_comb = 1;
                                    res_comb = 0;
                                end
                                else
                                    res_comb = (opa_r << (opb_r[SHIFT_W-1:0])) | opa_r >> (W - (opb_r[SHIFT_W-1:0]));
                                    res_comb[2*W-1 : 8] = 0;
                            end
                            `ROR_A_B : begin
                                if( |(opb_r[(W-1) : (SHIFT_W+1)])) begin
                                    res_comb = 0;
                                    err_comb = 1;
                                end
                                else
                                    res_comb = (opa_r >> opb_r[SHIFT_W-1:0]) | opa_r << (W - opb_r[SHIFT_W-1:0]);
                                    res_comb[2*W-1 : 8] = 0;
                            end
                            default : err_comb = 1;
                        endcase
                    end

                    default : err_comb = 1;
                endcase
            end
        end
        else begin
           res_comb = 0;
           err_comb = 0;
           cout_comb = 0;
           ov_comb = 0;
           g_comb = 0;
           l_comb = 0;
           e_comb = 0;
           res_mult = 0;
        end



    end

    always@(posedge clk, posedge rst) begin
        if(rst) begin
            RES <= 0;
            COUT <= 0;
            OV <= 0;
            G <= 0;
            L <= 0;
            E <= 0;
            ERR  <= 0;
        end
        else if(CE) begin

            if((cmd_r == `MULT_SHIFT_A || cmd_r == `MULT_INC) && mode_r == 1) begin
                res_mult <= res_comb;
                RES <= res_mult;
            end
            else begin
                RES <= res_comb;
            end
                COUT <= cout_comb;
                OV <= ov_comb;
                G <= g_comb;
                L <= l_comb;
                E <= e_comb;
                ERR  <= err_comb;

        end
    end
endmodule
