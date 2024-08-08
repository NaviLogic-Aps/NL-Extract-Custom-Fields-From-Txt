pageextension 70550 "NL General Ledger Setup" extends "General Ledger Setup"
{
    actions
    {
        addafter("Change Payment &Tolerance")
        {
            action("NL Generate Codeunit")
            {
                ApplicationArea = All;
                Caption = 'Generate Excel File from Objects Txt [NL]';
                Image = ExportReceipt;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    NLCreateTxtFile: Codeunit "NL Create Txt File";
                begin
                    NLCreateTxtFile.Run();
                end;
            }
            action("NL Generate Deletion Code")
            {
                ApplicationArea = All;
                Caption = 'Generate Deletion Code [NL]';
                Image = ExportReceipt;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    NLCreateDeletionCode: Codeunit "NL Create Deletion Code";
                begin
                    NLCreateDeletionCode.Run();
                end;
            }
        }
    }
}
