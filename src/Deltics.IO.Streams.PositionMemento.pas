
{$i deltics.io.streams.inc}

  unit Deltics.IO.Streams.PositionMemento;


interface

  uses
    Classes,
    Deltics.Memento,
    Deltics.IO.Streams.Interfaces;


  type
    IStreamPositionMemento = interface(IMemento)
    ['{33F5550E-47E1-492B-8CCE-9254F7389FB4}']
      function get_Position: Int64;
      procedure set_Position(const aValue: Int64);
      property Position: Int64 read get_Position write set_Position;
    end;


    TStreamPositionMemento = class(TMemento, IStreamPositionMemento)
    { IStreamMemento - - - - - - - - - - - - - - - - - - - - }
    protected
      function get_Position: Int64;
      procedure set_Position(const aValue: Int64);

    private
      fStream: TStream;
      fPosition: Int64;
    protected
      constructor Create(const aStream: TStream);
      procedure DoRecall; override;
      procedure DoRefresh; override;
    end;


    StreamPositionMemento = class
    public
      class function Create(const aStream: IStream): IStreamPositionMemento; overload;
      class function Create(const aStream: TStream): IStreamPositionMemento; overload;
    end;


  {$ifdef ClassHelpers}
    StreamPositionMementoClassHelper = class helper for TStream
      function PositionMemento: IStreamPositionMemento; {$ifdef InlineMethods} inline; {$endif}
    end;
  {$endif}


implementation


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function StreamPositionMemento.Create(const aStream: IStream): IStreamPositionMemento;
  begin
    result := TStreamPositionMemento.Create(aStream.Stream);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function StreamPositionMemento.Create(const aStream: TStream): IStreamPositionMemento;
  begin
    result := TStreamPositionMemento.Create(aStream);
  end;





{ TStreamPositionMemento ------------------------------------------------------------------------- }

  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  constructor TStreamPositionMemento.Create(const aStream: TStream);
  begin
    inherited Create;

    fStream := aStream;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TStreamPositionMemento.get_Position: Int64;
  begin
    result := fPosition;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TStreamPositionMemento.set_Position(const aValue: Int64);
  begin
    fPosition := aValue;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TStreamPositionMemento.DoRecall;
  begin
    fStream.Position := fPosition;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TStreamPositionMemento.DoRefresh;
  begin
    fPosition := fStream.Position;
  end;




{$ifdef ClassHelpers}
  function StreamPositionMementoClassHelper.PositionMemento: IStreamPositionMemento;
  begin
    result := StreamPositionMemento.Create(self);
  end;
{$endif}





end.
