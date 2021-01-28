
{$i deltics.io.streams.inc}

  unit Deltics.IO.Streams.Buffered.Reader;


interface

  uses
    Classes,
    Deltics.IO.Streams.Buffered,
    Deltics.IO.Streams.Interfaces;


  type
    TBufferedStreamReader = class(TBufferedStream, IStreamReader)
    private
      fBufferEnd: PByte;
      function FillBuffer: Integer; {$ifdef InlineMethods} inline; {$endif}
    protected
      function get_EOF: Boolean;
      function get_Remaining: Int64;
      function get_Size: Int64;
      procedure AcquireStream(const aStream: TStream; const aIsOwn: Boolean); override;
      procedure ResetBuffer;
    public
      constructor Create(const aStream: TStream; const aBufSize: Integer = 4096);
      function Read(var aBuffer; aCount: Integer): Integer; override;
      function ReadInto(const aStream: IStream; aCount: Integer): Integer; overload;
      function ReadInto(const aStream: TStream; aCount: Integer): Integer; overload;
      function Seek(const aOffset: Int64; aOrigin: TSeekOrigin): Int64; override;
      function Write(const aBuffer; aCount: Integer): Integer; override;
    end;



implementation

  uses
    Deltics.Exceptions,
    Deltics.Pointers,
    Deltics.Pointers.Memory,
    Deltics.IO.Streams.Decorator;



{ TBufferedStreamReader -------------------------------------------------------------------------- }

  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TBufferedStreamReader.AcquireStream(const aStream: TStream;
                                                const aIsOwn: Boolean);
  begin
    inherited;

    FillBuffer;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TBufferedStreamReader.ResetBuffer;
  begin
    fBufferPointer  := fBuffer;
    fBufferEnd      := fBuffer;

    // Next read will start from current stream position

    fBufferPosition := Stream.Position;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  constructor TBufferedStreamReader.Create(const aStream: TStream;
                                           const aBufSize: Integer);
  begin
    inherited;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamReader.FillBuffer: Integer;
  begin
    fBufferPosition := Stream.Position;

    result := Stream.Read(fBuffer^, fBufferSize);

    fBufferEnd      := Memory.ByteOffset(fBuffer, result);
    fBufferPointer  := fBuffer;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamReader.get_EOF: Boolean;
  begin
    result := (fBufferPointer = fBufferEnd) and (Stream.Position = Stream.Size);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamReader.get_Remaining: Int64;
  begin
    result := Stream.Size - Position;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamReader.get_Size: Int64;
  begin
    result := Stream.Size;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamReader.Read(var aBuffer; aCount: Integer): Integer;
  var
    bufferedBytes: Integer;
  begin
    result := 0;

    if (fBufferPointer = fBufferEnd) then
      if (FillBuffer = 0) then
        EXIT;

    bufferedBytes := Integer(fBufferEnd) - Integer(fBufferPointer);

    if (aCount >= bufferedBytes) then
    begin
      Memory.Copy(fBufferPointer, @aBuffer, bufferedBytes);
      Dec(aCount, bufferedBytes);

      result := bufferedBytes;

      if aCount > 0 then
        result := result + Stream.Read(PByte(Int64(@aBuffer) + bufferedBytes)^, aCount);

      ResetBuffer;
    end
    else
    begin
      Memory.Copy(fBufferPointer, @aBuffer, aCount);

      Inc(fBufferPointer, aCount);
      result := aCount;
    end;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamReader.ReadInto(const aStream: IStream; aCount: Integer): Integer;
  begin
    result := ReadInto(aStream.Stream, aCount);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamReader.ReadInto(const aStream: TStream;
                                                aCount: Integer): Integer;
  const
    MAX_BYTES = 64 * 1024;
  var
    dest: TMemoryStream absolute aStream;
    buf: array[1..MAX_BYTES] of Byte;
    cnt: Integer;
    buffered: Integer;
    writer: IStreamWriter;
  begin
    if aStream is TMemoryStream then
    begin
      dest.Size := dest.Size + aCount;

      buffered := Int64(fBufferEnd) - Int64(fBufferPointer);
      if buffered > 0 then
      begin
        Memory.Copy(fBufferPointer, Memory.ByteOffset(dest.Memory, dest.Position), buffered);
        ResetBuffer;

        Dec(aCount, buffered);
      end;

      result := buffered + Stream.Read(PByte(Int64(dest.Memory) + dest.Position + buffered)^, aCount);

      fBufferPosition := Stream.Position;
    end
    else
    begin
      result := 0;
      writer := BufferedStream.CreateWriter(aStream);

      repeat
        cnt := Read(buf, MAX_BYTES);
        writer.Write(buf, cnt);

        Inc(result, cnt);
      until cnt = 0;
    end;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamReader.Seek(const aOffset: Int64;
                                            aOrigin: TSeekOrigin): Int64;
  var
    newPos: UInt64;
  begin
    case aOrigin of
      soBeginning : newPos := aOffset;
      soCurrent   : newPos := Position + aOffset;
      soEnd       : newPos := Size - aOffset;
    else
      newPos := Position;
    end;

    result := newPos;

    if newPos = Position then
      EXIT;

    if (newPos < fBufferPosition) or (newPos >= fBufferPosition + UInt64(fBufferSize)) then
    begin
      Stream.Seek(newPos, soBeginning);
      Resetbuffer;
    end
    else
      fBufferPointer := Memory.ByteOffset(fBuffer, (newPos - fBufferPosition));
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TBufferedStreamReader.Write(const aBuffer; aCount: Integer): Integer;
  resourcestring
    rsfWriteNotSupported = 'Write operations are not supported by %s';
  begin
    raise ENotSupported.CreateFmt(rsfWriteNotSupported, [ClassName]);
  end;









end.
