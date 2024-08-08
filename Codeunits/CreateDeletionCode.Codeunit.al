codeunit 70551 "NL Create Deletion Code"
{
    trigger OnRun()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        FileManagement: Codeunit "File Management";
        FileInstream: InStream;
        ExcelRowIndex: Integer;
        LastRowNo: Integer;
        UploadExcelFile_Lbl: Label 'Upload Excel File';
        ListOfFields: List of [Text];
        ListOfRecords: List of [Text];
        FileName: Text;
        FromFile: Text;
        SheetName: Text;
    begin
        if UploadIntoStream(UploadExcelFile_Lbl, '', '', FromFile, FileInstream) then begin
            FileName := FileManagement.GetFileName(FromFile);
            SheetName := TempExcelBuffer.SelectSheetsNameStream(FileInstream);
        end;
        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.OpenBookStream(FileInstream, SheetName);
        TempExcelBuffer.ReadSheet();
        TempExcelBuffer.Reset();

        //Skip headers
        TempExcelBuffer.FindLast();
        LastRowNo := TempExcelBuffer."Row No.";
        for ExcelRowIndex := 2 to LastRowNo do begin
            if TempExcelBuffer.Get(ExcelRowIndex, 1) then begin //Record No.
                ListOfRecords.Add(TempExcelBuffer."Cell Value as Text");
                if TempExcelBuffer.Get(ExcelRowIndex, 3) then //Field No.
                    ListOfFields.Add(TempExcelBuffer."Cell Value as Text");
            end;
        end;
        GenerateDeletionCode(ListOfFields, ListOfRecords);
    end;

    procedure GenerateDeletionCode(ListOfFields: List of [Text]; ListOfRecords: List of [Text])
    var
        TempBlob: Codeunit "Temp Blob";
        GeneratedDate: Date;
        GeneratedDateTime: DateTime;
        InStream_L: InStream;
        RecordCount: Integer;
        FileName_Lbl: Label 'DeletionCU_%1_%2.txt', Comment = '%1 = Date, %2 = User ID';
        OutStream_L: OutStream;
        BaseCode: Text;
        DeletionText: Text;
        FileName: Text;
        Crlf: Text[2];
        GeneratedTime: Time;
    begin
        Crlf[1] := 13;
        Crlf[2] := 10;

        GeneratedDateTime := CURRENTDATETIME;
        if Evaluate(GeneratedDate, Format(GeneratedDateTime)) then;
        if Evaluate(GeneratedTime, Format(GeneratedDateTime)) then;

        RecordCount := ListOfRecords.Count;
        BaseCode := 'OBJECT Codeunit 59999 NL Delete Custom Fields' + Crlf +
                    '{' + Crlf +
                    '  OBJECT-PROPERTIES' + Crlf +
                    '  {' + Crlf +
                    '    Date=%3;' + Crlf + //08/07/24
                    '    Time=%4;' + Crlf + //[ 4:14:47 PM]
                    '    Modified=Yes;' + Crlf +
                    '    Version List=NL1.00;' + Crlf +
                    '  }' + Crlf +
                    '  PROPERTIES' + Crlf +
                    '  {' + Crlf +
                    '    OnRun=VAR' + Crlf +
                    '            RecordRef@1000000000 : RecordRef;' + Crlf +
                    '            FieldRef@1000000001 : FieldRef;' + Crlf +
                    '            Records@1000000002 : ARRAY [%2] OF Integer;' + Crlf +
                    '            Fields@1000000003 : ARRAY [%2] OF Integer;' + Crlf +
                    '            Index@1000000004 : Integer;' + Crlf +
                    '            TempVariant@1000000005 : Variant;' + Crlf +
                    '          BEGIN' + Crlf +
                    '            %1' + Crlf +
                    '' + Crlf +
                    '            FOR Index := 1 TO ARRAYLEN(Records) DO BEGIN' + Crlf +
                    '                IF Records[Index] = 0 THEN EXIT;' + Crlf +
                    '                IF Fields[Index] = 0 THEN EXIT;' + Crlf +
                    '' + Crlf +
                    '                RecordRef.OPEN(Records[Index]);' + Crlf +
                    '                FieldRef := RecordRef.FIELD(Fields[Index]);' + Crlf +
                    '                CASE FORMAT(FieldRef.TYPE) OF' + Crlf +
                    '                  '' Date'':' + Crlf +
                    '                  FieldRef.VALUE:=0D;' + Crlf +
                    '                  ''DateTime'':' + Crlf +
                    '                  FieldRef.VALUE:=0DT;' + Crlf +
                    '                  ''Time'':' + Crlf +
                    '                  FieldRef.VALUE:=0T;' + Crlf +
                    '                  ELSE' + Crlf +
                    '                    FieldRef.VALUE := TempVariant;' + Crlf +
                    '                END;' + Crlf +
                    '' + Crlf +
                    '                RecordRef.MODIFY();' + Crlf +
                    '                RecordRef.CLOSE();' + Crlf +
                    '            END;' + Crlf +
                    '          END;' + Crlf +
                    '' + Crlf +
                    '  }' + Crlf +
                    '  CODE' + Crlf +
                    '  {' + Crlf +
                    '' + Crlf +
                    '    BEGIN' + Crlf +
                    '    {' + Crlf +
                    '      _________________________________________________________________________________' + Crlf +
                    '' + Crlf +
                    '      >> NaviLogic - alias "NL"' + Crlf +
                    '      _________________________________________________________________________________' + Crlf +
                    '' + Crlf +
                    '      %5' + Crlf + //NL1.00:2024.04.18:DPC (Dennis Puggaard Christensen)
                    '        CHANGES' + Crlf +
                    '        - 01: Autogenerated code to empty custom fields' + Crlf +
                    '' + Crlf +
                    '      _________________________________________________________________________________' + Crlf +
                    '' + Crlf +
                    '      << NaviLogic - alias "NL"' + Crlf +
                    '      _________________________________________________________________________________' + Crlf +
                    '    }' + Crlf +
                    '    END.' + Crlf +
                    '  }' + Crlf +
                    '}';

        DeletionText :=
        StrSubstNo(
            BaseCode,
            GetFieldDimensionAssignmentText(ListOfFields, ListOfRecords),
            RecordCount,
            Format(GeneratedDate, 2048, '<Closing><Month,2>/<Day,2>/<Year>'), //08/07/24
            Format(GeneratedTime, 2048, '<Hours12>:<Minutes,2>:<Seconds,2><Second dec.> <AM/PM>'), //[ 4:14:47 PM]
            'NL1.00:' + Crlf + Format(GeneratedDate, 2048, '<Year>.<Month,2>.<Day,2>') + 'NL (NaviLogic)'
        //NL1.00:2024.04.18:DPC (Dennis Puggaard Christensen)
        );

        TempBlob.CreateOutStream(OutStream_L);
        TempBlob.CreateInStream(InStream_L);
        OutStream_L.WriteText(DeletionText);
        CopyStream(OutStream_L, InStream_L);
        FileName := StrSubstNo(FileName_Lbl, CurrentDateTime, UserId);

        DownloadFromStream(InStream_L, '', '', '', FileName);
    end;

    procedure GetFieldDimensionAssignmentText(ListOfFields: List of [Text]; ListOfRecords: List of [Text]) DimensionAssignmentText: Text;
    var
        Index: Integer;
        Crlf: Text[2];
    begin
        Crlf[1] := 13;
        Crlf[2] := 10;
        for Index := 1 to ListOfRecords.Count do begin
            DimensionAssignmentText +=
                '            Records[' + Format(Index) + '] := ' + ListOfRecords.Get(Index) + ';' + Crlf +
                '            Fields[' + Format(Index) + '] := ' + ListOfFields.Get(Index) + ';' + Crlf;
        end;
    end;
}
