
{$i deltics.io.streams.inc}

  unit Deltics.IO.Streams.Decorator;

interface

  uses
    Classes,
    Deltics.Multicast,
    Deltics.IO.Streams.Interfaces;


  type
    TStreamDecorator = class(TStream, IUnknown,
                                      IOnDestroy,
                                      IStreamBase,
                                      IStream)
     // IUnknown
    private
      fRefCount: Integer;
    protected
      function QueryInterface(const aIID: TGUID; out aObj): HResult; stdcall;
      function _AddRef: Integer; stdcall;
      function _Release: Integer; stdcall;

    // IStreamBase
    protected
      function get_Position: Int64;
      procedure set_Position(aValue: Int64);
    public
      function Seek(const aOffset: Int64; aOrigin: TSeekOrigin = soBeginning): Int64; override;
      function SeekBackward(const aCount: Int64): Int64;
      function SeekForward(const aCount: Int64): Int64;
      function SeekTo(const aPosition: Int64): Int64;
      procedure SeekEnd;
      procedure SeekStart;

    // IStream
    protected
      function get_OnDestroy: TMulticastNotify;
      function get_Stream: TStream;
    public
      function Read(var aBuffer; aCount: Integer): Integer; override;
      function Write(const aBuffer; aCount: Integer): Integer; override;

    // IOnDestroy
    private
      fOnDestroy: TMulticastNotify;
    public
      property OnDestroy: TMulticastNotify read get_OnDestroy implements IOnDestroy;

    private
      fIsBeingDestroyed: Boolean;
      fOwnsStream: Boolean;
      fStreamIntf: IStream;   // Used solely to maintain +1 ref count if constructed with an IStream
      fStream: TStream;
      function get_EOF: Boolean;
    protected
      function GetSize: Int64; override;
      procedure SetSize(const aValue: Int64); override;
      procedure AcquireStream(const aStream: IStream); overload;
      procedure AcquireStream(const aStream: TStream; const aOwned: Boolean); overload; virtual;
      procedure ReleaseStream; virtual;
      property EOF: Boolean read get_EOF;
      property IsBeingDestroyed: Boolean read fIsBeingDestroyed;
      property Stream: TStream read fStream;
    public
      class function NewInstance: TObject; override;
      constructor Create(const aStream: IStream); overload;
      constructor Create(const aStream: TStream); overload;
      destructor Destroy; override;
      procedure AfterConstruction; override;
      procedure BeforeDestruction; override;
      property Position: Int64 read get_Position write set_Position;
      property Size: Int64 read GetSize write SetSize;
    end;


implementation

  uses
    Windows;


{ TStreamDecorator ------------------------------------------------------------------------------- }

  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  constructor TStreamDecorator.Create(const aStream: TStream);
  begin
    inherited Create;

    AcquireStream(aStream, FALSE);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  constructor TStreamDecorator.Create(const aStream: IStream);
  begin
    inherited Create;

    AcquireStream(aStream);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  destructor TStreamDecorator.Destroy;
  begin
    fOnDestroy.DoEvent;
    fOnDestroy.Free;

    ReleaseStream;

    inherited;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamDecorator.get_EOF: Boolean;
  begin
    result := (fStream.Position = fStream.Size);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TStreamDecorator.AcquireStream(const aStream: IStream);
  begin
    // We do not own a stream by interface reference, even if we hold the sole
    //  reference to it.  'Owning' the stream means being directly responsible
    //  for Free'ing it, which takes place automatically if the stream is
    //  reference counted.

    AcquireStream(aStream.Stream, FALSE);

    fStreamIntf := aStream;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TStreamDecorator.AcquireStream(const aStream: TStream;
                                           const aOwned: Boolean);
  begin
    if Assigned(fStream) then
      ReleaseStream;

    fStream := aStream;

    fOwnsStream := aOwned and Assigned(fStream);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamDecorator.GetSize: Int64;
  begin
    result := fStream.Size;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamDecorator.get_Stream: TStream;
  begin
    result := fStream;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamDecorator.Read(var aBuffer; aCount: Integer): Integer;
  begin
    result := Stream.Read(aBuffer, aCount);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TStreamDecorator.ReleaseStream;
  begin
    if fOwnsStream then
      fStream.Free;

    fStreamIntf := NIL;
    fStream     := NIL;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamDecorator.Seek(const aOffset: Int64; aOrigin: TSeekOrigin): Int64;
  begin
    result := Stream.Seek(aOffset, aOrigin);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TStreamDecorator.SetSize(const aValue: Int64);
  begin
    Stream.Size := aValue;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamDecorator.Write(const aBuffer; aCount: Integer): Integer;
  begin
    result := Stream.Write(aBuffer, aCount);
  end;



  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TStreamDecorator.AfterConstruction;
  begin
    inherited;
    InterlockedDecrement(fRefCount);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TStreamDecorator.BeforeDestruction;
  begin
    fIsBeingDestroyed := TRUE;
    inherited;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamDecorator.get_OnDestroy: TMulticastNotify;
  begin
    if NOT IsBeingDestroyed and NOT Assigned(fOnDestroy) then
      fOnDestroy := TMulticastNotify.Create(self);

    result := fOnDestroy;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamDecorator.get_Position: Int64;
  begin
    result := Stream.Position;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function TStreamDecorator.NewInstance: TObject;
  var
    stream: TStreamDecorator absolute result;
  begin
    result := inherited NewInstance;

    // Ensure a minimum reference count of 1 during execution of the constructors
    //  to protect against _Release destroying ourselves as a result of interface
    //  references being passed around

    InterlockedIncrement(stream.fRefCount);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamDecorator.QueryInterface(const aIID: TGUID; out aObj): HResult;
  begin
    if GetInterface(aIID, aObj) then
      Result := 0
    else
      Result := E_NOINTERFACE;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamDecorator.SeekBackward(const aCount: Int64): Int64;
  begin
    result := Seek(-aCount, soCurrent);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TStreamDecorator.SeekEnd;
  begin
    Seek(0, soFromEnd);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamDecorator.SeekForward(const aCount: Int64): Int64;
  begin
    result := Seek(aCount, soCurrent);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TStreamDecorator.SeekStart;
  begin
    Seek(0, soBeginning);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamDecorator.SeekTo(const aPosition: Int64): Int64;
  begin
    result := Seek(aPosition, soBeginning);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TStreamDecorator.set_Position(aValue: Int64);
  begin
    Stream.Position := aValue;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamDecorator._AddRef: Integer;
  begin
    if NOT IsBeingDestroyed then
      result := InterlockedIncrement(fRefCount)
    else
      result := 1;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamDecorator._Release: Integer;
  begin
    if NOT IsBeingDestroyed then
    begin
      result := InterlockedDecrement(fRefCount);

      if result = 0 then
        Destroy;
    end
    else
      result := 1;
  end;







end.
