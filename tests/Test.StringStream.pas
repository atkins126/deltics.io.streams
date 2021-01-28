
{$i deltics.inc}

  unit Test.StringStream;


interface

  uses
    Deltics.Smoketest;


  type
    StringStream = class(TTest)
    private
      fSutDestroyedCallCount: Integer;
      procedure SutDestroyed(aSender: TObject);
    published
      procedure SupportsExplicitLifetime;
      procedure SupportsReferenceCountedLifetime;
    end;


implementation


  uses
    Deltics.Multicast,
    Deltics.IO.Streams;



{ StringStream }

  procedure StringStream.SutDestroyed(aSender: TObject);
  begin
    Inc(fSutDestroyedCallCount);
  end;



  procedure StringStream.SupportsExplicitLifetime;
  var
    sut: TStringStream;
  begin
    Test.RaisesNoException;

    sut := TStringStream.Create('foo');
    sut.Free;
  end;



  procedure StringStream.SupportsReferenceCountedLifetime;
  var
    sut: IStream;
  begin
    fSutDestroyedCallCount := 0;

    sut := TStringStream.Create('foo');
    sut.OnDestroy.Add(SutDestroyed);

    sut := NIL;

    Test('OnDestroy was called').Assert(fSutDestroyedCallCount).Equals(1);
  end;





end.
