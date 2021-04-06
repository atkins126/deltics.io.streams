
{$i deltics.io.streams.inc}

  unit Deltics.IO.Streams.MemoryStream;


interface

  uses
    Classes,
    Deltics.Multicast,
    Deltics.Memory,
    Deltics.IO.Streams.Interfaces;


  type
    TMemoryStream = class(TStream, IUnknown,
                                   IStream,
                                   IMemoryStream,
                                   IOnDestroy)
     // IUnknown
    private
      fRefCount: Integer;
    protected
      function QueryInterface(const aIID: TGUID; out aObj): HResult; stdcall;
      function _AddRef: Integer; stdcall;
      function _Release: Integer; stdcall;

    // IStream
    protected
      function get_OnDestroy: TMulticastNotify;
      function get_Position: Int64;
      function get_Stream: TStream;
      procedure set_Position(aValue: Int64);
      function SeekBackward(const aCount: Int64): Int64;
      function SeekForward(const aCount: Int64): Int64;
      function SeekTo(const aPosition: Int64): Int64;
      procedure SeekEnd;
      procedure SeekStart;

    // IMemoryStream
    protected
      function get_BaseAddress: Pointer;

    // IOnDestroy
    private
      fOnDestroy: TMulticastNotify;
    public
      property OnDestroy: TMulticastNotify read get_OnDestroy implements IOnDestroy;

    private
      fIsBeingDestroyed: Boolean;
      fBaseAddress: Pointer;
      fPosition: NativeUInt;
      fSize: NativeUInt;
    protected
      procedure SetBaseAddress(const aBaseAddress: Pointer); overload;
      procedure SetBaseAddress(const aBaseAddress: Pointer; const aSize: NativeUInt); overload; virtual;
      procedure SetSize(const aSize: NativeUInt);
      procedure UpdateBaseAddress(const aBaseAddress: Pointer; const aSize: NativeUInt);
      property IsBeingDestroyed: Boolean read fIsBeingDestroyed;
    public
      class function NewInstance: TObject; override;
      constructor Create; virtual;
      destructor Destroy; override;
      procedure AfterConstruction; override;
      procedure BeforeDestruction; override;
      function Read(var aBuffer; aCount: LongInt): LongInt; override;
      function Seek(const aOffset: Int64; aOrigin: TSeekOrigin): Int64; override;
      function Write(const aBuffer; aCount: LongInt): LongInt; override;
      property BaseAddress: Pointer read fBaseAddress;
      property Position: NativeUInt read fPosition;
      property Size: NativeUInt read fSize;
    end;


    MemoryStream = class
    public
      class function Create(const aSize: NativeUInt): IMemoryStream; overload;
      class function Create(const aBaseAddress: Pointer; const aSize: NativeUInt): IMemoryStream; overload;
      class function Create(const aCapacity: NativeUInt; const aCapacityIncrement: Word): IMemoryStream; overload;
      class function CreateCopy(const aSourceAddress: Pointer; const aSize: NativeUInt): IMemoryStream;
      class function CreateFrom(const aStream: TStream): IMemoryStream;
      class function CreateNew: IMemoryStream;
    end;




implementation

  uses
    Windows,
    Deltics.Exceptions,
    Deltics.IO.Streams.MemoryStream.Dynamic,
    Deltics.IO.Streams.MemoryStream.Fixed;




  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  constructor TMemoryStream.Create;
  begin
    if ClassType = TMemoryStream then
      raise EInvalidOperation.Create('Cannot create a TMemoryStream.  Use a TFixedMemoryStream or TDynamicMemoryStream');
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  destructor TMemoryStream.Destroy;
  begin
    fOnDestroy.DoEvent;
    fOnDestroy.Free;

    inherited;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TMemoryStream.AfterConstruction;
  begin
    inherited;
    InterlockedDecrement(fRefCount);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TMemoryStream.BeforeDestruction;
  begin
    fIsBeingDestroyed := TRUE;
    inherited;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TMemoryStream.get_BaseAddress: Pointer;
  begin
    result := fBaseAddress;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TMemoryStream.get_OnDestroy: TMulticastNotify;
  begin
    if NOT IsBeingDestroyed and NOT Assigned(fOnDestroy) then
      fOnDestroy := TMulticastNotify.Create(self);

    result := fOnDestroy;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TMemoryStream.get_Position: Int64;
  begin
    result := inherited Position;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TMemoryStream.get_Stream: TStream;
  begin
    result := self;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function TMemoryStream.NewInstance: TObject;
  var
    stream: TMemoryStream absolute result;
  begin
    result := inherited NewInstance;

    // Ensure a minimum reference count of 1 during execution of the constructors
    //  to protect against _Release destroying ourselves as a result of interface
    //  references being passed around

    InterlockedIncrement(stream.fRefCount);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TMemoryStream.QueryInterface(const aIID: TGUID; out aObj): HResult;
  begin
    if GetInterface(aIID, aObj) then
      Result := 0
    else
      Result := E_NOINTERFACE;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TMemoryStream.Seek(const aOffset: Int64;
                                    aOrigin: TSeekOrigin): Int64;
  begin
    case aOrigin of
      soBeginning : result := aOffset;
      soCurrent   : result := Int64(fPosition) + aOffset;
      soEnd       : result := Int64(fSize) + aOffset;
    else
      result := Position;
    end;

    if (result < 0)  then
      raise EInvalidOperation.Create('BOF! Attempted to Seek to a Position before the beginning of the stream');

    if (result > fSize) then
      raise EInvalidOperation.Create('EOF! Attempted to Seek to a Position beyond the end of the stream');

    fPosition := result;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TMemoryStream.SeekBackward(const aCount: Int64): Int64;
  begin
    result := Seek(-aCount, soCurrent);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TMemoryStream.SeekEnd;
  begin
    Seek(0, soFromEnd);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TMemoryStream.SeekForward(const aCount: Int64): Int64;
  begin
    result := Seek(aCount, soCurrent);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TMemoryStream.SeekStart;
  begin
    Seek(0, soBeginning);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TMemoryStream.SeekTo(const aPosition: Int64): Int64;
  begin
    result := Seek(aPosition, soBeginning);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TMemoryStream.SetBaseAddress(const aBaseAddress: Pointer);
  begin
    fBaseAddress := aBaseAddress;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TMemoryStream.SetBaseAddress(const aBaseAddress: Pointer;
                                         const aSize: NativeUInt);
  begin
    fBaseAddress  := aBaseAddress;
    fSize         := aSize;
    fPosition     := 0;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TMemoryStream.SetSize(const aSize: NativeUInt);
  begin
    fSize := aSize;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TMemoryStream.UpdateBaseAddress(const aBaseAddress: Pointer;
                                            const aSize: NativeUInt);
  begin
    fBaseAddress  := aBaseAddress;
    fSize         := aSize;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TMemoryStream.set_Position(aValue: Int64);
  begin
    Seek(aValue, soBeginning);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TMemoryStream._AddRef: Integer;
  begin
    if NOT IsBeingDestroyed then
      result := InterlockedIncrement(fRefCount)
    else
      result := 1;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TMemoryStream._Release: Integer;
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



  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TMemoryStream.Read(var aBuffer; aCount: Integer): LongInt;
  begin
    result := aCount;
    if NativeUInt(result) > Size - Position then
      result := Size - Position;

    if result <= 0 then
      EXIT;

    Memory.Copy(Memory.Offset(BaseAddress, Position), result, @aBuffer);
    Seek(result, soCurrent);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TMemoryStream.Write(const aBuffer; aCount: LongInt): LongInt;
  begin
    raise EInvalidOperation.Create('Cannot Write to a TMemoryStream.  Use a TFixedMemoryStream or TDynamicMemoryStream');
  end;






{ MemoryStream ----------------------------------------------------------------------------------- }

  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function MemoryStream.Create(const aSize: NativeUInt): IMemoryStream;
  begin
    result := TFixedMemoryStream.Create(aSize);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function MemoryStream.Create(const aBaseAddress: Pointer;
                                     const aSize: NativeUInt): IMemoryStream;
  begin
    result := TFixedMemoryStream.Create(aBaseAddress, aSize);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function MemoryStream.Create(const aCapacity: NativeUInt;
                                     const aCapacityIncrement: Word): IMemoryStream;
  begin
    result := TDynamicMemoryStream.Create(aCapacity, aCapacityIncrement);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function MemoryStream.CreateCopy(const aSourceAddress: Pointer;
                                         const aSize: NativeUInt): IMemoryStream;
  begin
    result := TFixedMemoryStream.Create(aSize);

    CopyMemory(result.BaseAddress, aSourceAddress, aSize);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function MemoryStream.CreateFrom(const aStream: TStream): IMemoryStream;
  var
    oldPos: Int64;
  begin
    result := TFixedMemoryStream.Create(aStream.Size);

    oldPos := aStream.Position;
    aStream.Seek(0, soBeginning);
    aStream.Read(result.BaseAddress^, aStream.Size);
    aStream.Seek(oldPos, soBeginning);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function MemoryStream.CreateNew: IMemoryStream;
  begin
    result := TDynamicMemoryStream.Create;
  end;






end.

