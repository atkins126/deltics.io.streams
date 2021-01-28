
{$i deltics.inc}

  unit Test.DynamicMemoryStream;


interface

  uses
    Deltics.Smoketest;


  type
    DynamicMemoryStream = class(TTest)
    private
      fSutDestroyedCallCount: Integer;
      procedure SutDestroyed(aSender: TObject);
    published
      procedure SupportsExplicitLifetime;
      procedure SupportsReferenceCountedLifetime;
      procedure AllowsWritingToEmptyStream;
      procedure AllowsWritingBeyondEndOfStream;
    end;


implementation


  uses
    Deltics.Multicast,
    Deltics.IO.Streams;



{ StringStream }

  procedure DynamicMemoryStream.SutDestroyed(aSender: TObject);
  begin
    Inc(fSutDestroyedCallCount);
  end;



  procedure DynamicMemoryStream.AllowsWritingToEmptyStream;
  var
    sut: IMemoryStream;
    value: Integer;
  begin
    value := 42;
    sut := MemoryStream.CreateNew;

    sut.Write(value, sizeof(value));

    Test('Value written').Assert(Integer(sut.BaseAddress^)).Equals(value);
  end;


  procedure DynamicMemoryStream.AllowsWritingBeyondEndOfStream;
  var
    sut: IMemoryStream;
    value: Integer;
    bytesWritten: Integer;
  begin
    value := 42;
    sut   := MemoryStream.Create(2, 2);

    bytesWritten := sut.Write(value, sizeof(value));

    Test('bytesWritten').Assert(bytesWritten).Equals(4);
    Test('Value written').Assert(Integer(sut.BaseAddress^)).Equals(42);
  end;



  procedure DynamicMemoryStream.SupportsExplicitLifetime;
  var
    sut: TDynamicMemoryStream;
  begin
    Test.RaisesNoException;

    sut := TDynamicMemoryStream.Create;
    sut.Free;
  end;



  procedure DynamicMemoryStream.SupportsReferenceCountedLifetime;
  var
    sut: IStream;
  begin
    fSutDestroyedCallCount := 0;

    sut := MemoryStream.CreateNew;
    sut.OnDestroy.Add(SutDestroyed);

    sut := NIL;

    Test('OnDestroy was called').Assert(fSutDestroyedCallCount).Equals(1);
  end;





end.
