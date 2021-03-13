
{$i deltics.io.streams.inc}

  unit Deltics.IO.Streams.Buffered.Writer;


interface

  uses
    Classes,
    Deltics.IO.Streams.Buffered,
    Deltics.IO.Streams.Interfaces;


  type
    TBufferedStreamWriter = class(TBufferedStream, IStreamWriter)
    protected
      procedure AcquireStream(const aStream: TStream; const aIsOwn: Boolean); override;
      function GetSize: Int64; override;
    public
      constructor Create(const aStream: TStream; const aBufSize: Integer);
      destructor Destroy; override;
      function CopyFrom(const aStream: IStream; aCount: Integer): Integer; overload;
      function CopyFrom(const aStream: TStream; aCount: Integer): Integer; overload;
      procedure Flush; {$ifdef InlineMethods} inline; {$endif}
      function Read(var aBuffer; aCount: Integer): Integer; override;
      function Rewrite(aOffset: Int64; const aBuffer; aCount: Integer): Integer;
      function Seek(const aOffset: Int64; aOrigin: TSeekOrigin): Int64; override;
      function Write(const aBuffer; aCount: Integer): Integer; override;
    end;




implementation

  uses
    Deltics.Exceptions,
    Deltics.Memory,
    Deltics.IO.Streams.Decorator;


{ TBufferedStreamWriter -------------------------------------------------------------------------- }

  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TBufferedStreamWriter.AcquireStream(const aStream: TStream;
                                                const aIsOwn: Boolean);
  begin
    inherited;
    fBufferPointer := fBuffer;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  constructor TBufferedStreamWriter.Create(const aStream: TStream; const aBufSize: Integer);
  begin
    inherited;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  destructor TBufferedStreamWriter.Destroy;
  begin
    Flush;

    inherited;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TBufferedStreamWriter.Flush;
  begin
    if (fBufferPointer = fBuffer) then  // Nothing to write
      EXIT;

    Stream.Write(fBuffer^, Integer(fBufferPointer) - Integer(fBuffer));
    fBufferPointer := fBuffer;

    fBufferPosition := Stream.Position;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamWriter.GetSize: Int64;
  begin
    result := Stream.Size;
    if (Stream.Position = Stream.Size) then
      Inc(result, Integer(fBufferPointer) - Integer(fBuffer));
  end;


  function TBufferedStreamWriter.CopyFrom(const aStream: IStream; aCount: Integer): Integer;
  begin
    result := CopyFrom(aStream.Stream, aCount);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamWriter.CopyFrom(const aStream: TStream;
                                                aCount: Integer): Integer;
  begin
    Flush;

    result := aCount;

    while aCount > fBufferSize do
    begin
      Inc(fBufferPointer, aStream.Read(fBuffer^, fBufferSize));
      Flush;

      Dec(aCount, fBufferSize);
    end;

    if aCount > 0 then
      Inc(fBufferPointer, aStream.Read(fBuffer^, aCount));
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamWriter.Read(var aBuffer; aCount: Integer): Integer;
  resourcestring
    rsfReadNotSupported = 'Read operations are not supported by %s';
  begin
    raise ENotSupported.CreateFmt(rsfReadNotSupported, [ClassName]);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamWriter.Rewrite(aOffset: Int64; const aBuffer; aCount: Integer): Integer;
  begin
    // TODO: Optimise for cases where aOffset is within the current write buffer

    // For now, we simply ensure that any pending writes are flushed before re-writing
    //  directly using the stream itself.  The next Write operation will resume
    //  employing the buffer.

    Flush;

    Stream.Position := aOffset;
    Stream.Write(aBuffer, aCount);
    Stream.Position := Stream.Size;

    fBufferPosition := Stream.Position;

    result := aCount;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamWriter.Seek(const aOffset: Int64;
                                            aOrigin: TSeekOrigin): Int64;
  begin
    Flush;
    Stream.Seek(aOffset, aOrigin);

    fBufferPosition := Stream.Position;

    result := Position;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamWriter.Write(const aBuffer; aCount: Integer): Integer;
  begin
    result := aCount;

    if (aCount = 0) then
      EXIT;

    // If we're writing more than will fit into the buffer (even if currently
    //  empty) then flush the buffer and write directly to the stream.

    if (aCount >= fBufferSize) then
    begin
      Flush;
      result := Stream.Write(aBuffer, aCount);
      EXIT;
    end;

    // If what we are writing will overflow the space remaining in the buffer
    //  then flush the buffer and buffer what we were asked to write.

    if (aCount >= (fBufferSize - (Integer(fBufferPointer) - Integer(fBuffer)))) then
      Flush;

    Memory.Copy(@aBuffer, aCount, fBufferPointer);
    Inc(fBufferPointer, aCount);
  end;









end.
