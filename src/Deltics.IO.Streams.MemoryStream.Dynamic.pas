
{$i deltics.io.streams.inc}

  unit Deltics.IO.Streams.MemoryStream.Dynamic;


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
    TDynamicMemoryStream = class(TMemoryStream, IDynamicMemoryStream)
    // IDynamicMemoryStream
    protected
      function get_Capacity: NativeUInt;
      procedure set_Capacity(const aCapacity: NativeUInt);

    private
      fCapacity: NativeUInt;
      fCapacityIncrement: Word;
      procedure IncreaseCapacity;
      procedure ReleaseMemory;
    public
      constructor Create; reintroduce; overload;
      constructor Create(const aInitialCapacity: NativeUInt; const aCapacityIncrement: Word = 1024); reintroduce; overload;
      destructor Destroy; override;
      function Write(const aBuffer; aCount: LongInt): LongInt; override;
      property Capacity: NativeUInt read fCapacity;
    end;



implementation

  uses
    Classes,
    Windows,
    Deltics.Exceptions;



{ TFixedMemoryStream ----------------------------------------------------------------------------- }

  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  constructor TDynamicMemoryStream.Create;
  begin
    Create(1024, 1024);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  constructor TDynamicMemoryStream.Create(const aInitialCapacity: NativeUInt;
                                          const aCapacityIncrement: Word);
  begin
    inherited Create;

    fCapacityIncrement := aCapacityIncrement;

    set_Capacity(aInitialCapacity);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  destructor TDynamicMemoryStream.Destroy;
  begin
    ReleaseMemory;

    inherited;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TDynamicMemoryStream.get_Capacity: NativeUInt;
  begin
    result := fCapacity;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TDynamicMemoryStream.IncreaseCapacity;
  begin
    if fCapacityIncrement = 0 then
      raise EInvalidOperation.Create('DynamicMemoryStream does not allow writing beyond the InitialCapacity');

    set_Capacity(Capacity + fCapacityIncrement);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TDynamicMemoryStream.ReleaseMemory;
  var
    ptr: Pointer;
  begin
    ptr := BaseAddress;
    if NOT Assigned(ptr) then
      EXIT;

    FreeMem(ptr, Capacity);
    SetBaseAddress(NIL, 0);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TDynamicMemoryStream.set_Capacity(const aCapacity: NativeUInt);
  var
    ptr: Pointer;
  begin
    ptr := BaseAddress;
    ReallocMem(ptr, aCapacity);
    SetBaseAddress(ptr);

    fCapacity := aCapacity;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TDynamicMemoryStream.Write(const aBuffer; aCount: LongInt): LongInt;
  var
    newSize: NativeUInt;
  begin
    result := aCount;
    if Position + NativeUInt(aCount) > Capacity then
      IncreaseCapacity;

    newSize := Size;
    if Position + NativeUInt(aCount) > newSize then
      newSize := Position + NativeUInt(aCount);

    Memory.Copy(@aBuffer, result, Memory.Offset(BaseAddress, Position));
    SetSize(newSize);

    Seek(result, soCurrent);
  end;






end.

