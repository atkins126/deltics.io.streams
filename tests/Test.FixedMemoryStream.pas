
{$i deltics.inc}

  unit Test.FixedMemoryStream;


interface

  uses
    Deltics.Smoketest;


  type
    FixedMemoryStream = class(TTest)
    private
      fSutDestroyedCallCount: Integer;
      procedure SutDestroyed(aSender: TObject);
    published
      procedure SupportsExplicitLifetime;
      procedure SupportsReferenceCountedLifetime;
      procedure AllowsWritingToAllocatedMemory;
      procedure DoesNotAllowWritingBeyondEndOfStream;
    end;


implementation


  uses
    Deltics.Multicast,
    Deltics.IO.Streams;



{ StringStream }

  procedure FixedMemoryStream.SutDestroyed(aSender: TObject);
  begin
    Inc(fSutDestroyedCallCount);
  end;



  procedure FixedMemoryStream.AllowsWritingToAllocatedMemory;
  var
    ptr: Pointer;
    sut: IStream;
    value: Integer;
  begin
    Getmem(ptr, 4);
    try
      sut := MemoryStream.Create(ptr, 4);
      sut.Write(value, 4);

      Test('Value written').Assert(Integer(ptr^)).Equals(value);

    finally
      FreeMem(ptr);
    end;
  end;


  procedure FixedMemoryStream.DoesNotAllowWritingBeyondEndOfStream;
  var
    sut: IStream;
    value: Integer;
    bytesWritten: Integer;
  begin
    sut := MemoryStream.Create(2);

    bytesWritten := sut.Write(value, 4);

    Test('bytesWritten').Assert(bytesWritten).Equals(2);
  end;



  procedure FixedMemoryStream.SupportsExplicitLifetime;
  var
    sut: TFixedMemoryStream;
  begin
    Test.RaisesNoException;

    sut := TFixedMemoryStream.Create;
    sut.Free;
  end;



  procedure FixedMemoryStream.SupportsReferenceCountedLifetime;
  var
    sut: IStream;
  begin
    fSutDestroyedCallCount := 0;

    sut := MemoryStream.Create(@self, 4);
    sut.OnDestroy.Add(SutDestroyed);

    sut := NIL;

    Test('OnDestroy was called').Assert(fSutDestroyedCallCount).Equals(1);
  end;





end.
