
{$i deltics.io.streams.inc}

  unit Deltics.IO.Streams.StringStream;


interface

  uses
    Classes,
    Deltics.Multicast,
    Deltics.IO.Streams.Interfaces;


  type
    TStringStream = class(Classes.TStringStream, IUnknown,
                                                 IStream,
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

    // IOnDestroy
    private
      fOnDestroy: TMulticastNotify;
    public
      property OnDestroy: TMulticastNotify read get_OnDestroy implements IOnDestroy;

    private
      fIsBeingDestroyed: Boolean;
    protected
      property IsBeingDestroyed: Boolean read fIsBeingDestroyed;
    public
      class function NewInstance: TObject; override;
      destructor Destroy; override;
      procedure AfterConstruction; override;
      procedure BeforeDestruction; override;
    {$ifdef __DELPHI2007}
    public
      constructor Create; reintroduce; overload;
      procedure SaveToFile(const aFilename: String);
    {$endif}
    end;



implementation

  uses
    Windows;


{$ifdef __DELPHI2007}
  constructor TStringStream.Create;
  begin
    inherited Create('');
  end;


  procedure TStringStream.SaveToFile(const aFilename: String);
  var
    s: String;
    strm: TStream;
  begin
    strm := TFileStream.Create(aFileName, fmCreate);
    try
      s := DataString;
      strm.Write(s[1], Length(s) * SizeOf(Char));

    finally
      strm.Free;
    end;
  end;
{$endif __DELPHI2007}


  procedure TStringStream.AfterConstruction;
  begin
    inherited;
    InterlockedDecrement(fRefCount);
  end;


  procedure TStringStream.BeforeDestruction;
  begin
    fIsBeingDestroyed := TRUE;
    inherited;
  end;


  destructor TStringStream.Destroy;
  begin
    fOnDestroy.DoEvent;
    fOnDestroy.Free;

    inherited;
  end;


  function TStringStream.get_OnDestroy: TMulticastNotify;
  begin
    if NOT IsBeingDestroyed and NOT Assigned(fOnDestroy) then
      fOnDestroy := TMulticastNotify.Create(self);

    result := fOnDestroy;
  end;


  function TStringStream.get_Position: Int64;
  begin
    result := inherited Position;
  end;


  function TStringStream.get_Stream: TStream;
  begin
    result := self;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function TStringStream.NewInstance: TObject;
  var
    stream: TStringStream absolute result;
  begin
    result := inherited NewInstance;

    // Ensure a minimum reference count of 1 during execution of the constructors
    //  to protect against _Release destroying ourselves as a result of interface
    //  references being passed around

    InterlockedIncrement(stream.fRefCount);
  end;


  function TStringStream.QueryInterface(const aIID: TGUID; out aObj): HResult;
  begin
    if GetInterface(aIID, aObj) then
      Result := 0
    else
      Result := E_NOINTERFACE;
  end;


  function TStringStream.SeekBackward(const aCount: Int64): Int64;
  begin
    result := Seek(-aCount, soCurrent);
  end;


  procedure TStringStream.SeekEnd;
  begin
    Seek(0, soFromEnd);
  end;


  function TStringStream.SeekForward(const aCount: Int64): Int64;
  begin
    result := Seek(aCount, soCurrent);
  end;


  procedure TStringStream.SeekStart;
  begin
    Seek(0, soBeginning);
  end;


  function TStringStream.SeekTo(const aPosition: Int64): Int64;
  begin
    result := Seek(aPosition, soBeginning);
  end;


  procedure TStringStream.set_Position(aValue: Int64);
  begin
    Position := aValue;
  end;


  function TStringStream._AddRef: Integer;
  begin
    if NOT IsBeingDestroyed then
      result := InterlockedIncrement(fRefCount)
    else
      result := 1;
  end;


  function TStringStream._Release: Integer;
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
