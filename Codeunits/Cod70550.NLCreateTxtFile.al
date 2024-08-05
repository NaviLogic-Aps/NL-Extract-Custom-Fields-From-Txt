codeunit 70550 "NL Create Txt File"
{
    /*
    How to use this extenion (BC14 extension):
    1. Export all standard tables from NAVision as .txt file
    2. Run this extension, by going to "General Ledger Stup" page and pressing "Generate Codeunit [NL]" button from Home actions area
    3. When it's requesting from you the .txt file, you need to select the exported one at point 1.
    4. When execution is ready it automatically will download the generated excel file that contains custom fields
    */
    trigger OnRun()
    var
        AtLeastOneTable: Boolean;
        CurrentTableId: Text;
        CurrentTableName: Text;
        FieldName: Text;
        FieldNo: Text;
        FieldType: Text;
        FileName: Text;
        FieldsText: Text;
        Index: Integer;
        InStream: InStream;
        InStream2: InStream;
        ListWithTablesId: List of [Text];
        ListWithTablesName: List of [Text];
        NewOneLine: Text;
        NewOneLineAux: Text;
        NoOfFields: Integer;
        NoOfTables: Integer;
        OneLine: Text;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFileName: Label 'Custom fields_%1_%2';
    begin
        FieldsText := 'FIELDS';
        NoOfTables := 0;
        NoOfFields := 0;
        AtLeastOneTable := false;

        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();

        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddColumn('Table No.', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
        TempExcelBuffer.AddColumn('Table Name', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Field No.', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
        TempExcelBuffer.AddColumn('Field Name', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Field Type', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);

        if UploadIntoStream('Upload the text file containg standard tables implementation', '', '', FileName, InStream) then begin
            while not InStream.EOS do begin
                InStream.ReadText(OneLine);

                if OneLine.Contains('OBJECT Table') then begin
                    CurrentTableName := '';
                    CurrentTableId := '';
                    NoOfTables := NoOfTables + 1;
                    NewOneLine := DelStr(OneLine, 1, StrLen('OBJECT Table') + 1);
                    Index := 1;
                    while Index <= StrLen(NewOneLine) do begin
                        if NewOneLine[Index] = ' ' then begin
                            CurrentTableName := DelStr(NewOneLine, 1, Index);
                            CurrentTableId := DelStr(NewOneLine, Index, StrLen(NewOneLine));
                            Index := StrLen(NewOneLine);
                        end else
                            Index := Index + 1;
                    end;
                end else begin
                    if (StrPos(UpperCase(OneLine), FieldsText) > 0) then begin
                        if StrLen(OneLine) = StrLen(FieldsText) then
                            NoOfFields := NoOfFields + 1
                        else begin
                            if StrLen(OneLine) <> StrLen(FieldsText) then begin
                                NewOneLine := DELCHR(OneLine, '=', ' ');
                                if StrLen(NewOneLine) = StrLen(FieldsText) then
                                    NoOfFields := NoOfFields + 1;
                            end;
                        end;
                    end else begin
                        if NoOfFields = NoOfTables then begin
                            FieldName := '';
                            FieldType := '';
                            FieldNo := '';
                            NewOneLineAux := OneLine;
                            NewOneLine := DELCHR(OneLine, '=', ' ');
                            if (NewOneLine[2] in ['5', '6', '7', '8', '9']) and (NewOneLine[1] = '{') then begin
                                if StrPos(NewOneLine, ';;') > 0 then begin
                                    FieldNo := DelStr(NewOneLine, StrPos(NewOneLine, ';;'), StrLen(NewOneLine));
                                    FieldNo := DelStr(FieldNo, 1, 1);
                                    if StrLen(FieldNo) >= 5 then begin
                                        if ((NewOneLine[2] = '5') and (StrLen(FieldNo) = 5)) or
                                           ((NewOneLine[2] = '6') and (StrLen(FieldNo) = 5)) or
                                           ((NewOneLine[2] = '7') and (StrLen(FieldNo) = 5)) or
                                           ((NewOneLine[2] = '8') and (StrLen(FieldNo) = 5)) or
                                           ((NewOneLine[2] = '9') and (StrLen(FieldNo) = 5)) or
                                           ((NewOneLine[2] = '6') and (StrLen(FieldNo) = 7)) then begin
                                            NewOneLineAux := DelStr(NewOneLineAux, 1, StrPos(NewOneLineAux, ';'));
                                            NewOneLineAux := DelStr(NewOneLineAux, 1, StrPos(NewOneLineAux, ';'));
                                            FieldName := DelStr(NewOneLineAux, StrPos(NewOneLineAux, ';'), StrLen(NewOneLineAux));
                                            NewOneLineAux := DelStr(NewOneLineAux, 1, StrPos(NewOneLineAux, ';'));
                                            if StrPos(NewOneLineAux, ';') > 0 then
                                                FieldType := DelStr(NewOneLineAux, StrPos(NewOneLineAux, ';'), StrLen(NewOneLineAux))
                                            else if StrPos(NewOneLineAux, '}') > 0 then
                                                FieldType := DelStr(NewOneLineAux, StrPos(NewOneLineAux, '}'), StrLen(NewOneLineAux));
                                        end;
                                    end;
                                end;

                                if (StrLen(FieldName) > 0) and (StrLen(FieldType) > 0) and (StrLen(CurrentTableName) > 0) then begin
                                    if ListWithTablesName.Contains(CurrentTableName) = false then
                                        ListWithTablesName.Add(CurrentTableName);

                                    TempExcelBuffer.NewRow();
                                    TempExcelBuffer.AddColumn(CurrentTableId, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                                    TempExcelBuffer.AddColumn(CurrentTableName, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                    TempExcelBuffer.AddColumn(FieldNo, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                                    TempExcelBuffer.AddColumn(FieldName, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                    TempExcelBuffer.AddColumn(FieldType, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);

                                    if ListWithTablesId.Contains(CurrentTableId) = false then
                                        ListWithTablesId.Add(CurrentTableId);
                                    AtLeastOneTable := true;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end;

        TempExcelBuffer.CreateNewBook('Custom fields');
        TempExcelBuffer.WriteSheet('Custom fields', CompanyName, UserId);
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.SetFriendlyFilename(StrSubstNo(ExcelFileName, CurrentDateTime, UserId));
        TempExcelBuffer.OpenExcel();
    end;
}

