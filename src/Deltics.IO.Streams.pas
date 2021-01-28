{
  * X11 (MIT) LICENSE *

  Copyright © 2008 Jolyon Smith

  Permission is hereby granted, free of charge, to any person obtaining a copy of
   this software and associated documentation files (the "Software"), to deal in
   the Software without restriction, including without limitation the rights to
   use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
   of the Software, and to permit persons to whom the Software is furnished to do
   so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.


  * GPL and Other Licenses *

  The FSF deem this license to be compatible with version 3 of the GPL.
   Compatability with other licenses should be verified by reference to those
   other license terms.


  * Contact Details *

  Original author : Jolyon Smith
  skype           : deltics
  e-mail          : <EXTLINK mailto: jsmith@deltics.co.nz>jsmith@deltics.co.nz</EXTLINK>
  website         : <EXTLINK http://www.deltics.co.nz>www.deltics.co.nz</EXTLINK>
}

{$i deltics.io.streams.inc}

  unit Deltics.IO.Streams;


interface

  uses
  { vcl: }
    Classes,
    SysUtils,
  { deltics: }
    Deltics.Memento,
    Deltics.Strings,
    Deltics.IO.Streams.Buffered,
    Deltics.IO.Streams.Buffered.Reader,
    Deltics.IO.Streams.Buffered.Writer,
    Deltics.IO.Streams.Decorator,
    Deltics.IO.Streams.Interfaces,
    Deltics.IO.Streams.MemoryStream,
    Deltics.IO.Streams.MemoryStream.Dynamic,
    Deltics.IO.Streams.MemoryStream.Fixed,
    Deltics.IO.Streams.PositionMemento,
    Deltics.IO.Streams.StringStream;


  type
    IStream               = Deltics.IO.Streams.Interfaces.IStream;
    IStreamReader         = Deltics.IO.Streams.Interfaces.IStreamReader;
    IStreamWriter         = Deltics.IO.Streams.Interfaces.IStreamWriter;
    IMemoryStream         = Deltics.IO.Streams.Interfaces.IMemoryStream;
    IDynamicMemoryStream  = Deltics.IO.Streams.Interfaces.IDynamicMemoryStream;
    IFixedMemoryStream    = Deltics.IO.Streams.Interfaces.IFixedMemoryStream;

    TStreamDecorator  = Deltics.IO.Streams.Decorator.TStreamDecorator;
    TStringStream     = Deltics.IO.Streams.StringStream.TStringStream;

    TDynamicMemoryStream   = Deltics.IO.Streams.MemoryStream.Dynamic.TDynamicMemoryStream;
    TFixedMemoryStream     = Deltics.IO.Streams.MemoryStream.Fixed.TFixedMemoryStream;

    TBufferedStreamReader = Deltics.IO.Streams.Buffered.Reader.TBufferedStreamReader;
    TBufferedStreamWriter = Deltics.IO.Streams.Buffered.Writer.TBufferedStreamWriter;

    BufferedStream        = Deltics.IO.Streams.Buffered.BufferedStream;
    StreamPositionMemento = Deltics.IO.Streams.PositionMemento.StreamPositionMemento;


    MemoryStream = Deltics.IO.Streams.MemoryStream.MemoryStream;


  const
    soBeginning = Classes.soBeginning;
    soCurrent   = Classes.soCurrent;
    soFromEnd   = Classes.soFromEnd;



implementation




end.
