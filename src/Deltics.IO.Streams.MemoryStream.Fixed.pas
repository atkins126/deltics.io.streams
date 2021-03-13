
{$i deltics.io.streams.inc}

  unit Deltics.IO.Streams.MemoryStream.Fixed;


interface

  uses
    Deltics.Memory,
    Deltics.IO.Streams.Interfaces,
    Deltics.IO.Streams.MemoryStream;

  type
    {
      TFixedMemoryStream provides a stream implementation for reading/writing from/to
       a fixed area of memory.

      Attempts to Seek beyond the end of the fixed area (determined by the Size) will
       cause an EInvalidOperation exception.

      Attempts to Write beyond the end of the fixed area (determined by the Size) will
       silently fail with no bytes written or fewer bytes written than requested.

      The fixed area of memory accessed by the stream may be determined either by
       providing a BaseAddress and Size or Size only.  If only Size is provided then
       the fixed memory area is allocated by the stream and deallocated when the stream
       is destroyed.
    }
    TFixedMemoryStream = class(TMemoryStream)
    private
      fOwnsMemory: Boolean;
      procedure ReleaseMemory;
    public
      constructor Create; reintroduce; overload;
      constructor Create(const aSize: Int64); reintroduce; overload;
      constructor Create(const aBaseAddress: Pointer; const aSize: Int64); reintroduce; overload;
      destructor Destroy; override;
      procedure SetBaseAddress(const aBaseAddress: Pointer; const aSize: NativeUInt); override;
      function Write(const aBuffer; aCount: LongInt): LongInt; override;
    end;



implementation

  uses
    Classes,
    Windows,
    Deltics.Exceptions;



{ TFixedMemoryStream ----------------------------------------------------------------------------- }

  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  constructor TFixedMemoryStream.Create;
  begin
    raise EInvalidOperation.Create('A FixedMemoryStream must be created with at least a Size '
                                 + 'or a BaseAddress and Size');
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  constructor TFixedMemoryStream.Create(const aSize: Int64);
  var
    ptr: Pointer;
  begin
    inherited Create;

    GetMem(ptr, aSize);

    SetBaseAddress(ptr, aSize);

    fOwnsMemory := TRUE;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  constructor TFixedMemoryStream.Create(const aBaseAddress: Pointer;
                                        const aSize: Int64);
  begin
    inherited Create;

    SetBaseAddress(aBaseAddress, aSize);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  destructor TFixedMemoryStream.Destroy;
  begin
    ReleaseMemory;

    inherited;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TFixedMemoryStream.ReleaseMemory;
  var
    ptr: Pointer;
  begin
    if NOT fOwnsMemory then
      EXIT;

    ptr := BaseAddress;
    if Assigned(ptr) then
      FreeMem(ptr, Size);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TFixedMemoryStream.SetBaseAddress(const aBaseAddress: Pointer;
                                              const aSize: NativeUInt);
  begin
    ReleaseMemory;

    inherited;

    fOwnsMemory := FALSE;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFixedMemoryStream.Write(const aBuffer;
                                          aCount: Integer): LongInt;
  begin
    result := aCount;
    if NativeUInt(result) > (Size - Position) then
      result := Size - Position;

    if result <= 0 then
      EXIT;

    Memory.Copy(@aBuffer, result, Memory.Offset(BaseAddress, Position));
    Seek(result, soCurrent);
  end;




end.
