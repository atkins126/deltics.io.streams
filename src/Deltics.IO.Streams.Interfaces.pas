
{$i deltics.io.streams.inc}

  unit Deltics.IO.Streams.Interfaces;


interface

  uses
    Classes,
    Deltics.Multicast,
    Deltics.Pointers,
    Deltics.Strings;


  type
    IOnDestroy = Deltics.Multicast.IOn_Destroy;


    IStreamBase = interface
    ['{E7B89208-5C2C-4330-B12C-19540F05A5A8}']
      function get_Position: Int64;
      procedure set_Position(aValue: Int64);

      function Seek(const aOffset: Int64; aOrigin: TSeekOrigin = soBeginning): Int64;
      function SeekBackward(const aCount: Int64): Int64;
      function SeekForward(const aCount: Int64): Int64;
      function SeekTo(const aPosition: Int64): Int64;
      procedure SeekEnd;
      procedure SeekStart;

      property Position: Int64 read get_Position write set_Position;
    end;


    IStream = interface(IStreamBase)
    ['{6B4A0BFA-D1A4-4BFA-9DF1-3B741848607C}']
      function get_OnDestroy: TMulticastNotify;
      function get_Stream: TStream;
      function Read(var aBuffer; aCount: Integer): Integer;
      function Write(const aBuffer; aCount: Integer): Integer;

      property Stream: TStream read get_Stream;
      property OnDestroy: TMulticastNotify read get_OnDestroy;
    end;


    IStreamReader = interface(IStream)
    ['{8E65DAC5-24DF-4D1C-B070-58F0C459952B}']
      function get_EOF: Boolean;
      function get_Remaining: Int64;
      function get_Size: Int64;

      function Read(var aBuffer; aCount: Integer): Integer;
      function ReadInto(const aStream: IStream; aCount: Integer): Integer; overload;
      function ReadInto(const aStream: TStream; aCount: Integer): Integer; overload;

      property EOF: Boolean read get_EOF;
      property Remaining: Int64 read get_Remaining;
      property Size: Int64 read get_Size;
    end;


    IStreamWriter = interface(IStream)
    ['{8B92CCF9-F963-4512-AAEB-B2A7DD9EE8B8}']
      function CopyFrom(const aStream: IStream; aCount: Integer): Integer; overload;
      function CopyFrom(const aStream: TStream; aCount: Integer): Integer; overload;
      function Write(const aBuffer; aCount: Integer): Integer;
      function Rewrite(aOffset: Int64; const aBuffer; aCount: Integer): Integer;
    end;


    IMemoryStream = interface(IStream)
    ['{A12596C2-CE74-4153-8EAB-6CD68924CAD0}']
      function get_BaseAddress: Pointer;
      property BaseAddress: Pointer read get_BaseAddress;
    end;


    IDynamicMemoryStream = interface(IMemoryStream)
    ['{6A2AB0EB-9F45-4113-A88F-DB81AD91522F}']
      function get_Capacity: NativeUInt;
      procedure set_Capacity(const aCapacity: NativeUInt);
      property Capacity: NativeUInt read get_Capacity write set_Capacity;
    end;


    IFixedMemoryStream = interface(IMemoryStream)
    ['{592CC88F-F34D-4581-836A-C16E55062CA4}']
      procedure SetBaseAddress(const aBaseAddress: Pointer; const aSize: NativeUInt);
    end;




implementation



end.
