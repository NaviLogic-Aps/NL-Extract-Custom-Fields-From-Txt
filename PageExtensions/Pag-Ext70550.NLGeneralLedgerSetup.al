pageextension 70550 "NL General Ledger Setup" extends "General Ledger Setup"
{
    actions
    {
        addafter("Change Payment &Tolerance")
        {
            action("NL Generate Codeunit")
            {
                ApplicationArea = All;
                Caption = 'Generate Codeunit [NL]';
                Image = ExportReceipt;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ApprovalsMgmt: Codeunit "NL Create Txt File";
                begin
                    ApprovalsMgmt.Run();
                end;
            }
        }
    }
}
