
{$i deltics.io.streams.inc}

  unit Deltics.IO.Streams.Buffered;


interface

  uses
    Classes,
    Deltics.IO.Streams.Decorator,
    Deltics.IO.Streams.Interfaces;


  type
    TBufferedStream = class(TStreamDecorator, IUnknown)
    // IUnknown
    protected
      function QueryInterface(const aIID: TGUID; out aObj): HResult; stdcall;
      function _AddRef: Integer; stdcall;
      function _Release: Integer; stdcall;

    protected
      fBuffer: PByte;           // Base address of the Buffer
      fBufferSize: Integer;     // The size of the allocated Buffer
      fBufferPointer: PByte;    // The read/write pointer into the buffer
      fBufferPosition: UInt64;  // The Position of the Buffer contents in the underlying stream
      fIsDestroying: Boolean;
      fRefCount: Integer;
    protected
      function get_Position: Int64; virtual;
      procedure set_Position(aValue: Int64);
      function GetSize: Int64; override;
      procedure SetSize(const aValue: Int64); override;
      constructor Create(const aStream: TStream; const aBufferSize: Integer);
      property Buffer: PByte read fBuffer;
      property BufferSize: Integer read fBufferSize;
      property BufferPosition: UInt64 read fBufferPosition;
    public
      class function NewInstance: TObject; override;
      destructor Destroy; override;
      procedure BeforeDestruction; override;
      function Seek(const aOffset: Int64; aOrigin: TSeekOrigin): Int64; override;

      property Position: Int64 read get_Position write set_Position;
    end;


    BufferedStream = class
    public
      class function CreateReader(const aStream: TStream; const aBufSize: Integer = 4096): IStreamReader;
      class function CreateWriter(const aStream: TStream; const aBufSize: Integer = 4096): IStreamWriter;
    end;




implementation

  uses
    Windows,
    Deltics.Exceptions,
    Deltics.Pointers,
    Deltics.IO.Streams.Buffered.Reader,
    Deltics.IO.Streams.Buffered.Writer;



{ BufferedStream --------------------------------------------------------------------------------- }

  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function BufferedStream.CreateReader(const aStream: TStream;
                                              const aBufSize: Integer): IStreamReader;
  begin
    result := TBufferedStreamReader.Create(aStream, aBufSize);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function BufferedStream.CreateWriter(const aStream: TStream;
                                              const aBufSize: Integer): IStreamWriter;
  begin
    result := TBufferedStreamWriter.Create(aStream, aBufSize);
  end;





{ TBufferedStream -------------------------------------------------------------------------------- }

  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TBufferedStream.BeforeDestruction;
  begin
    fIsDestroying := TRUE;
    inherited;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  constructor TBufferedStream.Create(const aStream: TStream;
                                     const aBufferSize: Integer);
  begin
    GetMem(fBuffer, aBufferSize);
    fBufferSize := aBufferSize;

    inherited Create(aStream);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  destructor TBufferedStream.Destroy;
  begin
    FreeMem(fBuffer);

    inherited;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStream.QueryInterface(const aIID: TGUID; out aObj): HResult;
  begin
    if GetInterface(aIID, aObj) then
      result := 0
    else
      result := E_NOINTERFACE;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStream._AddRef: Integer;
  begin
    if NOT fIsDestroying then
      result := InterlockedIncrement(fRefCount)
    else
      result := 1;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStream._Release: Integer;
  begin
    if NOT fIsDestroying then
    begin
      result := InterlockedDecrement(fRefCount);

      if (fRefCount = 0) then
        Destroy;
    end
    else
      result := 1;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStream.GetSize: Int64;
  begin
    result := Stream.Size;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStream.get_Position: Int64;
  begin
    result := fBufferPosition + (IntPointer(fBufferPointer) - IntPointer(fBuffer));
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function TBufferedStream.NewInstance: TObject;
  var
    stream: TBufferedStream absolute result;
  begin
    result := inherited NewInstance;

    InterlockedIncrement(stream.fRefCount);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TBufferedStream.set_Position(aValue: Int64);
  begin
    Seek(aValue, soBeginning);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStream.Seek(const aOffset: Int64; aOrigin: TSeekOrigin): Int64;
  resourcestring
    rsfSeekNotSupported = 'Seek operations are not supported by %s';
  begin
    raise ENotSupported.CreateFmt(rsfSeekNotSupported, [ClassName]);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TBufferedStream.SetSize(const aValue: Int64);
  begin
    Stream.Size := aValue;
  end;










end.
