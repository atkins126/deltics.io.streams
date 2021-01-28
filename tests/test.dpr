
{$define CONSOLE}

{$i deltics.smoketest.inc}

  program test;

uses
  FastMM4,
  Deltics.Smoketest,
  Deltics.IO.Streams in '..\src\Deltics.IO.Streams.pas',
  Deltics.IO.Streams.Buffered in '..\src\Deltics.IO.Streams.Buffered.pas',
  Deltics.IO.Streams.Buffered.Reader in '..\src\Deltics.IO.Streams.Buffered.Reader.pas',
  Deltics.IO.Streams.Buffered.Writer in '..\src\Deltics.IO.Streams.Buffered.Writer.pas',
  Deltics.IO.Streams.Decorator in '..\src\Deltics.IO.Streams.Decorator.pas',
  Deltics.IO.Streams.Interfaces in '..\src\Deltics.IO.Streams.Interfaces.pas',
  Deltics.IO.Streams.InterfacedStream in '..\src\Deltics.IO.Streams.InterfacedStream.pas',
  Deltics.IO.Streams.StringStream in '..\src\Deltics.IO.Streams.StringStream.pas',
  Deltics.IO.Streams.MemoryStream in '..\src\Deltics.IO.Streams.MemoryStream.pas',
  Deltics.IO.Streams.MemoryStream.Fixed in '..\src\Deltics.IO.Streams.MemoryStream.Fixed.pas',
  Deltics.IO.Streams.MemoryStream.Dynamic in '..\src\Deltics.IO.Streams.MemoryStream.Dynamic.pas',
  Deltics.IO.Streams.PositionMemento in '..\src\Deltics.IO.Streams.PositionMemento.pas',
  Test.StringStream in 'Test.StringStream.pas',
  Test.FixedMemoryStream in 'Test.FixedMemoryStream.pas',
  Test.DynamicMemoryStream in 'Test.DynamicMemoryStream.pas';

begin
  TestRun.Test(StringStream);
  TestRun.Test(DynamicMemoryStream);
  TestRun.Test(FixedMemoryStream);
end.
